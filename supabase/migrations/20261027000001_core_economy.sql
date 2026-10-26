-- EcoPlanet fase 2: economia do loop principal.
--
-- Todas as mudanças de energia, oxigênio e pontos passam por estas funções.
-- Elas rodam como security definer, validam tudo no servidor e devolvem o
-- estado atualizado em JSON. As fórmulas estão espelhadas em
-- lib/features/player/domain/economy.dart (só para exibir custos na UI).
--
-- Erros de regra usam mensagens fixas que o app traduz:
--   not_authenticated, no_active_planet, invalid_slot, slot_taken,
--   invalid_species, not_enough_energy, invalid_upgrade,
--   upgrade_unavailable, max_level, not_enough_oxygen, invalid_steps

-- ---------------------------------------------------------------------------
-- Novas colunas
-- ---------------------------------------------------------------------------

-- Controle anti-trapaça dos passos (balde de 10 passos/s, até 1 hora).
-- Contas novas começam com o balde cheio.
alter table public.profiles
  add column last_step_sync_at timestamptz not null default now() - interval '1 hour',
  -- Última coleta de oxigênio (a coleta conta no máximo 60 s para trás).
  add column last_oxygen_at timestamptz not null default now();

-- Momento em que a árvore termina de crescer e passa a gerar oxigênio.
alter table public.user_trees
  add column ready_at timestamptz not null default now();

-- Upgrades liberados na loja. Crescimento e Automação chegam depois.
alter table public.upgrades
  add column is_available boolean not null default true;

update public.upgrades set is_available = false
where category in ('growth', 'automation');

-- ---------------------------------------------------------------------------
-- Funções auxiliares (schema privado, fora da API)
-- ---------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- Efeito total de uma categoria de upgrade para o usuário (nível x efeito).
create or replace function private.upgrade_bonus(p_user uuid, p_category text)
returns numeric
language sql
stable
set search_path = ''
as $$
  select coalesce(sum(uu.level * u.effect), 0)
  from public.user_upgrades uu
  join public.upgrades u on u.id = uu.upgrade_id
  where uu.user_id = p_user and u.category = p_category;
$$;

-- Custo em energia de uma espécie num planeta, com desconto do upgrade Custo
-- (máximo de 50%).
create or replace function private.tree_cost(
  p_species_cost integer,
  p_planet_base_cost numeric,
  p_cost_bonus numeric
)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select ceil(p_species_cost * (p_planet_base_cost / 10.0) * (1 - least(p_cost_bonus, 0.5)));
$$;

-- Custo em oxigênio para subir do nível atual para o próximo.
create or replace function private.upgrade_cost(
  p_base_cost numeric,
  p_multiplier numeric,
  p_current_level integer
)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select round(p_base_cost * power(p_multiplier, p_current_level), 2);
$$;

-- Garante o planeta atual do usuário e devolve o id de user_planets.
create or replace function private.current_user_planet(p_user uuid)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_id uuid;
begin
  select up.id into v_id
  from public.user_planets up
  join public.planets p on p.id = up.planet_id
  where up.user_id = p_user and up.completed_at is null
  order by p.order_index
  limit 1;

  if v_id is null and not exists (
    select 1 from public.user_planets where user_id = p_user
  ) then
    insert into public.user_planets (user_id, planet_id)
    select p_user, id from public.planets order by order_index limit 1
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

revoke all on all functions in schema private from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- RPC: planeta atual
-- ---------------------------------------------------------------------------
create or replace function public.ensure_current_planet()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;
  return private.current_user_planet(v_user);
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: energia por passos
-- ---------------------------------------------------------------------------
create or replace function public.add_step_energy(p_steps integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_bucket_start timestamptz;
  v_allowed integer;
  v_accepted integer;
  v_gained numeric;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;
  if p_steps is null or p_steps <= 0 then
    raise exception 'invalid_steps';
  end if;

  select * into v_profile from public.profiles where id = v_user for update;

  -- Balde: 10 passos por segundo, acumulando no máximo 1 hora.
  v_bucket_start := greatest(v_profile.last_step_sync_at, now() - interval '1 hour');
  v_allowed := floor(extract(epoch from (now() - v_bucket_start)) * 10);
  v_accepted := least(p_steps, greatest(v_allowed, 0));

  -- 100 passos = 1 energia, com bônus do upgrade Energia.
  v_gained := round(v_accepted / 100.0 * (1 + private.upgrade_bonus(v_user, 'energy')), 2);

  update public.profiles
  set energy = energy + v_gained,
      last_step_sync_at = v_bucket_start + make_interval(secs => v_accepted / 10.0),
      last_seen = now()
  where id = v_user
  returning * into v_profile;

  return jsonb_build_object(
    'accepted_steps', v_accepted,
    'energy_gained', v_gained,
    'energy', v_profile.energy
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: coleta de oxigênio (só com o app aberto; no máximo 60 s por coleta)
-- ---------------------------------------------------------------------------
create or replace function public.collect_oxygen()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_now timestamptz := now();
  v_window_start timestamptz;
  v_collected numeric;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_profile from public.profiles where id = v_user for update;

  v_window_start := greatest(v_profile.last_oxygen_at, v_now - interval '60 seconds');

  select coalesce(sum(
           s.oxygen_per_sec
           * greatest(0, extract(epoch from (v_now - greatest(v_window_start, t.ready_at))))
         ), 0)
  into v_collected
  from public.user_trees t
  join public.tree_species s on s.id = t.species_id
  where t.user_id = v_user and t.ready_at < v_now;

  v_collected := round(v_collected * (1 + private.upgrade_bonus(v_user, 'production')), 2);

  update public.profiles
  set oxygen = oxygen + v_collected,
      last_oxygen_at = v_now,
      last_seen = v_now
  where id = v_user
  returning * into v_profile;

  return jsonb_build_object(
    'oxygen_collected', v_collected,
    'oxygen', v_profile.oxygen
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: plantar árvore
-- ---------------------------------------------------------------------------
create or replace function public.plant_tree(p_slot_index integer, p_species_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_user_planet_id uuid;
  v_user_planet public.user_planets%rowtype;
  v_planet public.planets%rowtype;
  v_species public.tree_species%rowtype;
  v_cost numeric;
  v_grow_seconds numeric;
  v_tree public.user_trees%rowtype;
  v_completed boolean := false;
  v_points integer := 0;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_profile from public.profiles where id = v_user for update;

  v_user_planet_id := private.current_user_planet(v_user);

  select * into v_user_planet
  from public.user_planets
  where id = v_user_planet_id and completed_at is null
  for update;
  if not found then
    raise exception 'no_active_planet';
  end if;

  select * into v_planet from public.planets where id = v_user_planet.planet_id;

  if p_slot_index is null or p_slot_index < 0 or p_slot_index >= v_planet.total_slots then
    raise exception 'invalid_slot';
  end if;

  select * into v_species from public.tree_species where id = p_species_id;
  if not found then
    raise exception 'invalid_species';
  end if;

  if exists (
    select 1 from public.user_trees
    where user_planet_id = v_user_planet.id and slot_index = p_slot_index
  ) then
    raise exception 'slot_taken';
  end if;

  v_cost := private.tree_cost(
    v_species.cost, v_planet.base_cost, private.upgrade_bonus(v_user, 'cost')
  );
  if v_profile.energy < v_cost then
    raise exception 'not_enough_energy';
  end if;

  -- Upgrade Crescimento reduz o tempo (máximo de 50%).
  v_grow_seconds := v_species.grow_seconds
    * (1 - least(private.upgrade_bonus(v_user, 'growth'), 0.5));

  insert into public.user_trees (user_id, user_planet_id, species_id, slot_index, ready_at)
  values (
    v_user, v_user_planet.id, v_species.id, p_slot_index,
    now() + make_interval(secs => v_grow_seconds)
  )
  returning * into v_tree;

  update public.user_planets
  set reforested_slots = reforested_slots + 1
  where id = v_user_planet.id
  returning * into v_user_planet;

  -- Planeta concluído: marca e dá pontos (100 x ordem do planeta).
  if v_user_planet.reforested_slots >= v_planet.total_slots then
    v_completed := true;
    v_points := 100 * v_planet.order_index;
    update public.user_planets set completed_at = now() where id = v_user_planet.id;
  end if;

  update public.profiles
  set energy = energy - v_cost,
      total_points = total_points + v_points,
      last_seen = now()
  where id = v_user
  returning * into v_profile;

  return jsonb_build_object(
    'tree', jsonb_build_object(
      'id', v_tree.id,
      'species_id', v_tree.species_id,
      'slot_index', v_tree.slot_index,
      'planted_at', v_tree.planted_at,
      'ready_at', v_tree.ready_at
    ),
    'energy_spent', v_cost,
    'energy', v_profile.energy,
    'total_points', v_profile.total_points,
    'reforested_slots', v_user_planet.reforested_slots,
    'planet_completed', v_completed
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: comprar upgrade
-- ---------------------------------------------------------------------------
create or replace function public.buy_upgrade(p_upgrade_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_upgrade public.upgrades%rowtype;
  v_level integer;
  v_cost numeric;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_profile from public.profiles where id = v_user for update;

  select * into v_upgrade from public.upgrades where id = p_upgrade_id;
  if not found then
    raise exception 'invalid_upgrade';
  end if;
  if not v_upgrade.is_available then
    raise exception 'upgrade_unavailable';
  end if;

  select coalesce(
    (select level from public.user_upgrades
     where user_id = v_user and upgrade_id = p_upgrade_id),
    0
  ) into v_level;

  if v_level >= v_upgrade.max_level then
    raise exception 'max_level';
  end if;

  v_cost := private.upgrade_cost(v_upgrade.base_cost, v_upgrade.cost_multiplier, v_level);
  if v_profile.oxygen < v_cost then
    raise exception 'not_enough_oxygen';
  end if;

  insert into public.user_upgrades (user_id, upgrade_id, level, updated_at)
  values (v_user, p_upgrade_id, v_level + 1, now())
  on conflict (user_id, upgrade_id)
  do update set level = excluded.level, updated_at = excluded.updated_at;

  update public.profiles
  set oxygen = oxygen - v_cost,
      last_seen = now()
  where id = v_user
  returning * into v_profile;

  return jsonb_build_object(
    'upgrade_id', p_upgrade_id,
    'level', v_level + 1,
    'oxygen_spent', v_cost,
    'oxygen', v_profile.oxygen
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Permissões das RPCs: só usuários logados
-- ---------------------------------------------------------------------------
revoke execute on function
  public.ensure_current_planet(),
  public.add_step_energy(integer),
  public.collect_oxygen(),
  public.plant_tree(integer, bigint),
  public.buy_upgrade(bigint)
from public, anon;

grant execute on function
  public.ensure_current_planet(),
  public.add_step_energy(integer),
  public.collect_oxygen(),
  public.plant_tree(integer, bigint),
  public.buy_upgrade(bigint)
to authenticated;

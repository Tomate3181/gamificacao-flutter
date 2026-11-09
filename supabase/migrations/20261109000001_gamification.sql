-- EcoPlanet fase 3: missões de gameplay, conquistas e ranking global.
--
-- Missões agora são objetivos do próprio jogo (caminhar, plantar, coletar
-- oxigênio, comprar upgrades). O progresso é contado pelo servidor dentro
-- das RPCs da economia; o jogador inicia a missão e resgata a recompensa
-- quando chega na meta. Cada missão só rende uma vez por jogador.
--
-- Novos erros: invalid_mission, mission_not_started,
--   mission_already_completed, mission_not_ready

-- ---------------------------------------------------------------------------
-- Missões: troca o catálogo de missões ecológicas por missões de gameplay
-- ---------------------------------------------------------------------------
-- O app nunca gravou em user_missions antes desta fase.
delete from public.user_missions;
delete from public.missions;

alter table public.missions drop constraint missions_category_check;

alter table public.missions
  add constraint missions_category_check
    check (category in ('walking', 'planting', 'oxygen', 'upgrades')),
  add column goal_type text not null
    check (goal_type in ('steps', 'trees_planted', 'species_planted', 'upgrades_bought', 'oxygen_collected')),
  add column goal_value integer not null check (goal_value > 0),
  -- Espécie exigida (só em goal_type = 'species_planted').
  add column goal_species_id bigint references public.tree_species (id),
  add column energy_reward integer not null default 0 check (energy_reward >= 0),
  add column sort_order integer not null default 0,
  add constraint missions_goal_species_check
    check ((goal_type = 'species_planted') = (goal_species_id is not null));

comment on column public.missions.guidance is 'Dica curta de como cumprir a missão.';

-- Progresso desde que a missão foi iniciada (para em goal_value).
alter table public.user_missions
  add column progress numeric(14, 2) not null default 0 check (progress >= 0);

insert into public.missions
  (sort_order, title, description, guidance, category, difficulty, points, energy_reward, goal_type, goal_value, goal_species_id)
values
  (1, 'Aquecendo', 'Caminhe 200 passos.',
   'Dê uma volta com o celular no bolso. No navegador, use o modo demo do perfil.',
   'walking', 'easy', 30, 20, 'steps', 200, null),
  (2, 'Primeira semente', 'Plante sua primeira árvore.',
   'Toque numa região poluída do planeta e escolha uma espécie.',
   'planting', 'easy', 20, 20, 'trees_planted', 1, null),
  (3, 'Respira, planeta', 'Colete 50 de oxigênio.',
   'Árvores prontas geram oxigênio enquanto o app está aberto.',
   'oxygen', 'easy', 30, 20, 'oxygen_collected', 50, null),
  (4, 'Bosque em formação', 'Plante 10 árvores.',
   'Mudas são baratas: ótimas para avançar rápido.',
   'planting', 'medium', 60, 35, 'trees_planted', 10, null),
  (5, 'Jardim de bambu', 'Plante 3 bambus.',
   'O bambu cresce rápido e custa pouco.',
   'planting', 'medium', 50, 35, 'species_planted', 3,
   (select id from public.tree_species where name = 'Bambu')),
  (6, 'Trilha verde', 'Caminhe 1.000 passos.',
   'Cada 100 passos viram 1 de energia.',
   'walking', 'medium', 60, 35, 'steps', 1000, null),
  (7, 'Primeira melhoria', 'Compre um upgrade na loja.',
   'Junte oxigênio e visite a loja.',
   'upgrades', 'medium', 50, 35, 'upgrades_bought', 1, null),
  (8, 'Ar puro', 'Colete 500 de oxigênio.',
   'Espécies maiores geram mais oxigênio por segundo.',
   'oxygen', 'medium', 80, 35, 'oxygen_collected', 500, null),
  (9, 'Flor da estação', 'Plante uma cerejeira.',
   'A cerejeira é rara: junte energia antes.',
   'planting', 'hard', 100, 50, 'species_planted', 1,
   (select id from public.tree_species where name = 'Cerejeira')),
  (10, 'Maratonista do planeta', 'Caminhe 5.000 passos.',
   'Um passeio longo rende muita energia.',
   'walking', 'hard', 120, 50, 'steps', 5000, null);

-- A conquista de reciclagem vira uma conquista de plantio.
update public.achievements
set code = 'garden_master',
    name = 'Mestre jardineiro',
    description = 'Conclua três missões de plantio.',
    icon = 'garden',
    condition_value = 3,
    condition_category = 'planting'
where code = 'recycling_master';

-- ---------------------------------------------------------------------------
-- Funções auxiliares (privadas)
-- ---------------------------------------------------------------------------

-- Soma progresso às missões em andamento de um tipo de objetivo.
create or replace function private.bump_missions(
  p_user uuid,
  p_goal text,
  p_amount numeric,
  p_species bigint default null
)
returns void
language sql
set search_path = ''
as $$
  update public.user_missions um
  set progress = least(um.progress + p_amount, m.goal_value)
  from public.missions m
  where m.id = um.mission_id
    and um.user_id = p_user
    and um.status = 'in_progress'
    and m.goal_type = p_goal
    and (m.goal_species_id is null or m.goal_species_id = p_species)
    and p_amount > 0;
$$;

-- Desbloqueia as conquistas atingidas e devolve as novas.
create or replace function private.check_achievements(p_user uuid)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_new jsonb := '[]'::jsonb;
  v_metric bigint;
  r public.achievements%rowtype;
begin
  for r in
    select a.* from public.achievements a
    where not exists (
      select 1 from public.user_achievements ua
      where ua.user_id = p_user and ua.achievement_id = a.id
    )
    order by a.id
  loop
    v_metric := case r.condition_type
      when 'missions_completed' then (
        select count(*) from public.user_missions
        where user_id = p_user and status = 'completed')
      when 'mission_days' then (
        select count(distinct (completed_at at time zone 'America/Sao_Paulo')::date)
        from public.user_missions
        where user_id = p_user and status = 'completed')
      when 'category_missions' then (
        select count(*) from public.user_missions um
        join public.missions m on m.id = um.mission_id
        where um.user_id = p_user and um.status = 'completed'
          and m.category = r.condition_category)
      when 'planets_completed' then (
        select count(*) from public.user_planets
        where user_id = p_user and completed_at is not null)
      when 'trees_planted' then (
        select count(*) from public.user_trees where user_id = p_user)
      else 0
    end;

    if v_metric >= r.condition_value then
      insert into public.user_achievements (user_id, achievement_id)
      values (p_user, r.id)
      on conflict do nothing;
      v_new := v_new || jsonb_build_array(
        jsonb_build_object('id', r.id, 'name', r.name, 'icon', r.icon)
      );
    end if;
  end loop;

  return v_new;
end;
$$;

revoke all on all functions in schema private from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- RPCs da economia recriadas: agora também contam progresso das missões
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

  perform private.bump_missions(v_user, 'steps', v_accepted);

  return jsonb_build_object(
    'accepted_steps', v_accepted,
    'energy_gained', v_gained,
    'energy', v_profile.energy
  );
end;
$$;

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

  perform private.bump_missions(v_user, 'oxygen_collected', v_collected);

  return jsonb_build_object(
    'oxygen_collected', v_collected,
    'oxygen', v_profile.oxygen
  );
end;
$$;

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
  v_achievements jsonb;
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

  perform private.bump_missions(v_user, 'trees_planted', 1);
  perform private.bump_missions(v_user, 'species_planted', 1, v_species.id);
  v_achievements := private.check_achievements(v_user);

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
    , 'achievements_unlocked', v_achievements
  );
end;
$$;

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

  perform private.bump_missions(v_user, 'upgrades_bought', 1);

  return jsonb_build_object(
    'upgrade_id', p_upgrade_id,
    'level', v_level + 1,
    'oxygen_spent', v_cost,
    'oxygen', v_profile.oxygen
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: iniciar missão
-- ---------------------------------------------------------------------------
create or replace function public.start_mission(p_mission_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_row public.user_missions%rowtype;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;
  if not exists (select 1 from public.missions where id = p_mission_id) then
    raise exception 'invalid_mission';
  end if;

  insert into public.user_missions (user_id, mission_id, status, progress)
  values (v_user, p_mission_id, 'in_progress', 0)
  on conflict (user_id, mission_id) do nothing;

  select * into v_row
  from public.user_missions
  where user_id = v_user and mission_id = p_mission_id;

  return jsonb_build_object(
    'mission_id', p_mission_id,
    'status', v_row.status,
    'progress', v_row.progress
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: resgatar recompensa da missão
-- ---------------------------------------------------------------------------
create or replace function public.complete_mission(p_mission_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_mission public.missions%rowtype;
  v_row public.user_missions%rowtype;
  v_profile public.profiles%rowtype;
  v_achievements jsonb;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_mission from public.missions where id = p_mission_id;
  if not found then
    raise exception 'invalid_mission';
  end if;

  select * into v_profile from public.profiles where id = v_user for update;

  select * into v_row
  from public.user_missions
  where user_id = v_user and mission_id = p_mission_id
  for update;

  if not found then
    raise exception 'mission_not_started';
  end if;
  if v_row.status = 'completed' then
    raise exception 'mission_already_completed';
  end if;
  if v_row.progress < v_mission.goal_value then
    raise exception 'mission_not_ready';
  end if;

  update public.user_missions
  set status = 'completed', completed_at = now()
  where user_id = v_user and mission_id = p_mission_id;

  update public.profiles
  set total_points = total_points + v_mission.points,
      energy = energy + v_mission.energy_reward,
      last_seen = now()
  where id = v_user
  returning * into v_profile;

  v_achievements := private.check_achievements(v_user);

  return jsonb_build_object(
    'mission_id', p_mission_id,
    'points_earned', v_mission.points,
    'energy_earned', v_mission.energy_reward,
    'total_points', v_profile.total_points,
    'energy', v_profile.energy,
    'achievements_unlocked', v_achievements
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: ranking global (calculado no banco)
-- Expõe só posição, apelido e pontos. Devolve o top N e, sempre, a linha
-- do usuário logado (is_me = true), mesmo fora do top.
-- ---------------------------------------------------------------------------
create or replace function public.get_ranking(p_limit integer default 50)
returns table (rank_position bigint, nickname text, total_points integer, is_me boolean)
language sql
stable
security definer
set search_path = ''
as $$
  with ranked as (
    select
      p.id,
      p.nickname,
      p.total_points,
      rank() over (order by p.total_points desc) as rank_position,
      row_number() over (order by p.total_points desc, p.created_at) as row_index
    from public.profiles p
  )
  select r.rank_position, r.nickname, r.total_points, r.id = auth.uid()
  from ranked r
  where auth.uid() is not null
    and (r.row_index <= least(greatest(coalesce(p_limit, 50), 1), 100) or r.id = auth.uid())
  order by r.row_index;
$$;

-- ---------------------------------------------------------------------------
-- Permissões das RPCs: só usuários logados
-- ---------------------------------------------------------------------------
revoke execute on function
  public.start_mission(bigint),
  public.complete_mission(bigint),
  public.get_ranking(integer),
  public.add_step_energy(integer),
  public.collect_oxygen(),
  public.plant_tree(integer, bigint),
  public.buy_upgrade(bigint)
from public, anon;

grant execute on function
  public.start_mission(bigint),
  public.complete_mission(bigint),
  public.get_ranking(integer),
  public.add_step_energy(integer),
  public.collect_oxygen(),
  public.plant_tree(integer, bigint),
  public.buy_upgrade(bigint)
to authenticated;

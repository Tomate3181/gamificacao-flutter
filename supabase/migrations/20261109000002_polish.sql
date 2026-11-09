-- EcoPlanet fase 4: polimento.
--
-- 1. Planetas começam pequenos (10 regiões) e crescem 50% a cada planeta,
--    com teto de 200 regiões. O ciclo é infinito: depois do último planeta
--    do catálogo, o servidor cria o próximo (os temas se repetem).
-- 2. Oxigênio offline: collect_offline_oxygen() paga o tempo fora do app.
-- 3. Árvore radial de upgrades: 5 ramos com 5 nós cada. Um nó só pode ser
--    comprado quando o nó pai tem pelo menos 1 nível.
--
-- Novo erro de regra: upgrade_locked.

-- ---------------------------------------------------------------------------
-- 1. Planetas
-- ---------------------------------------------------------------------------

-- Regiões e custo base do planeta de ordem n.
create or replace function private.planet_slots(p_order integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select least(200, round(10 * power(1.5, p_order - 1)))::integer;
$$;

create or replace function private.planet_base_cost(p_order integer)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select round(10 * power(1.3, p_order - 1), 2);
$$;

-- Catálogo atualizado com os novos tamanhos.
update public.planets
set total_slots = private.planet_slots(order_index),
    base_cost = private.planet_base_cost(order_index);

-- Planetas em andamento que ficaram menores: árvores fora da nova grade
-- saem, o progresso é recontado e quem já encheu o planeta o conclui.
delete from public.user_trees t
using public.user_planets up, public.planets p
where t.user_planet_id = up.id
  and up.planet_id = p.id
  and up.completed_at is null
  and t.slot_index >= p.total_slots;

update public.user_planets up
set reforested_slots = (
  select count(*) from public.user_trees t where t.user_planet_id = up.id
)
where up.completed_at is null;

with done as (
  update public.user_planets up
  set completed_at = now()
  from public.planets p
  where p.id = up.planet_id
    and up.completed_at is null
    and up.reforested_slots >= p.total_slots
  returning up.user_id, p.order_index
)
update public.profiles pr
set total_points = pr.total_points + d.points
from (
  select user_id, sum(100 * order_index)::integer as points
  from done
  group by user_id
) d
where d.user_id = pr.id;

-- Garante a linha do catálogo para o planeta de ordem n e devolve o id.
-- Depois do 5º planeta os temas se repetem, com numeral no nome
-- (ex.: "Deserto Esquecido II").
create or replace function private.planet_for_order(p_order integer)
returns bigint
language plpgsql
set search_path = ''
as $$
declare
  v_id bigint;
  v_names text[] := array[
    'Deserto Esquecido', 'Floresta Adormecida', 'Arquipélago Turvo',
    'Tundra Silenciosa', 'Picos Cinzentos'
  ];
  v_themes text[] := array['desert', 'forest', 'island', 'tundra', 'mountain'];
  v_index integer := ((p_order - 1) % 5) + 1;
  v_cycle integer := ((p_order - 1) / 5) + 1;
begin
  select id into v_id from public.planets where order_index = p_order;
  if v_id is not null then
    return v_id;
  end if;

  insert into public.planets (order_index, name, theme, total_slots, base_cost)
  values (
    p_order,
    v_names[v_index] || case when v_cycle > 1 then ' ' || to_char(v_cycle, 'FMRN') else '' end,
    v_themes[v_index],
    private.planet_slots(p_order),
    private.planet_base_cost(p_order)
  )
  on conflict (order_index) do nothing
  returning id into v_id;

  if v_id is null then
    select id into v_id from public.planets where order_index = p_order;
  end if;
  return v_id;
end;
$$;

-- Planeta atual do usuário. Se todos estiverem concluídos, começa o próximo.
create or replace function private.current_user_planet(p_user uuid)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_id uuid;
  v_last integer;
begin
  select up.id into v_id
  from public.user_planets up
  join public.planets p on p.id = up.planet_id
  where up.user_id = p_user and up.completed_at is null
  order by p.order_index
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  select coalesce(max(p.order_index), 0) into v_last
  from public.user_planets up
  join public.planets p on p.id = up.planet_id
  where up.user_id = p_user;

  insert into public.user_planets (user_id, planet_id)
  values (p_user, private.planet_for_order(v_last + 1))
  on conflict (user_id, planet_id) do nothing
  returning id into v_id;

  -- Outra chamada criou ao mesmo tempo.
  if v_id is null then
    select up.id into v_id
    from public.user_planets up
    where up.user_id = p_user and up.completed_at is null
    limit 1;
  end if;

  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Árvore radial de upgrades
-- ---------------------------------------------------------------------------

alter table public.upgrades drop constraint upgrades_category_check;
alter table public.upgrades add constraint upgrades_category_check
  check (category in (
    'growth', 'production', 'cost', 'automation', 'energy',
    'offline', 'offline_hours'
  ));

alter table public.upgrades
  add column code text unique,
  -- Ramo da árvore onde o nó aparece. O efeito vem de category, que pode ser
  -- diferente do ramo (ex.: nó de oxigênio offline no ramo Produção).
  add column branch text
    check (branch in ('production', 'growth', 'cost', 'energy', 'offline')),
  -- Anel: 1 perto do centro, 4 na ponta.
  add column tier integer check (tier between 1 and 4),
  -- Posição dentro do ramo: -1 esquerda, 0 centro, 1 direita.
  add column branch_slot integer not null default 0
    check (branch_slot between -1 and 1),
  add column parent_id bigint references public.upgrades (id);

create index upgrades_parent_id_idx on public.upgrades (parent_id);

-- Os nós da raiz passam a ter 5 níveis. Quem comprou além disso recebe o
-- oxigênio desses níveis de volta.
update public.profiles pr
set oxygen = pr.oxygen + r.refund
from (
  select uu.user_id,
         sum(private.upgrade_cost(u.base_cost, u.cost_multiplier, l)) as refund
  from public.user_upgrades uu
  join public.upgrades u on u.id = uu.upgrade_id
  cross join lateral generate_series(5, uu.level - 1) as l
  where u.category in ('growth', 'production', 'cost', 'energy')
    and uu.level > 5
  group by uu.user_id
) r
where r.user_id = pr.id;

update public.user_upgrades uu
set level = 5, updated_at = now()
from public.upgrades u
where u.id = uu.upgrade_id
  and u.category in ('growth', 'production', 'cost', 'energy')
  and uu.level > 5;

-- Raízes dos ramos (os upgrades antigos).
update public.upgrades set
  code = 'production_1', branch = 'production', tier = 1, branch_slot = 0,
  max_level = 5, base_cost = 50, cost_multiplier = 1.5, effect = 0.10,
  is_available = true
where name = 'Fotossíntese Turbo';

update public.upgrades set
  code = 'growth_1', branch = 'growth', tier = 1, branch_slot = 0,
  max_level = 5, base_cost = 50, cost_multiplier = 1.5, effect = 0.05,
  is_available = true
where name = 'Adubo Estelar';

update public.upgrades set
  code = 'cost_1', branch = 'cost', tier = 1, branch_slot = 0,
  max_level = 5, base_cost = 50, cost_multiplier = 1.5, effect = 0.04,
  is_available = true
where name = 'Sementes Eficientes';

update public.upgrades set
  code = 'energy_1', branch = 'energy', tier = 1, branch_slot = 0,
  max_level = 5, base_cost = 50, cost_multiplier = 1.5, effect = 0.10,
  is_available = true
where name = 'Tênis Verde';

-- Automação (drones) continua fora da árvore.
update public.upgrades set code = 'automation', is_available = false
where name = 'Drones Plantadores';

insert into public.upgrades
  (code, branch, tier, branch_slot, category, name, description,
   max_level, base_cost, cost_multiplier, effect)
values
  ('offline_1', 'offline', 1, 0, 'offline', 'Sono Tranquilo',
   'Suas árvores rendem mais enquanto o app está fechado.', 5, 80, 1.5, 0.05)
on conflict (name) do nothing;

-- Nós filhos: (código, ramo, anel, posição, pai, efeito, nome, descrição,
-- níveis, custo base, multiplicador, efeito por nível). Ficam numa tabela
-- temporária e entram anel por anel, porque o pai precisa existir antes.
create temporary table upgrade_nodes_seed (
  code text, branch text, tier integer, branch_slot integer, parent_code text,
  category text, name text, description text, max_level integer,
  base_cost numeric, cost_multiplier numeric, effect numeric
);

insert into upgrade_nodes_seed
select * from (values
  -- Produção
  ('production_2',  'production', 2,  0, 'production_1',  'production',    'Folhas Largas',       'Folhas maiores captam mais luz e geram mais oxigênio.',  5,  200, 1.6, 0.10),
  ('production_3a', 'production', 3, -1, 'production_2',  'production',    'Copa Densa',          'Copas fechadas multiplicam o oxigênio.',                  3, 1000, 1.8, 0.20),
  ('production_3b', 'production', 3,  1, 'production_2',  'offline',       'Orvalho Noturno',     'O orvalho da noite rende oxigênio com o app fechado.',    3,  800, 1.8, 0.05),
  ('production_4',  'production', 4, -1, 'production_3a', 'production',    'Coração da Floresta', 'O planeta inteiro respira: muito mais oxigênio.',         1, 6000, 1.0, 0.50),
  -- Crescimento
  ('growth_2',      'growth',     2,  0, 'growth_1',      'growth',        'Chuva Mansa',         'Regas na hora certa: as mudas crescem mais rápido.',      5,  200, 1.6, 0.03),
  ('growth_3a',     'growth',     3, -1, 'growth_2',      'growth',        'Raízes Profundas',    'Raízes fortes encurtam o crescimento.',                   3, 1000, 1.8, 0.05),
  ('growth_3b',     'growth',     3,  1, 'growth_2',      'production',    'Seiva Doce',          'Árvores saudáveis produzem mais oxigênio.',               3,  800, 1.8, 0.10),
  ('growth_4',      'growth',     4, -1, 'growth_3a',     'growth',        'Primavera Eterna',    'O crescimento fica muito mais rápido.',                   1, 6000, 1.0, 0.15),
  -- Custo
  ('cost_2',        'cost',       2,  0, 'cost_1',        'cost',          'Solo Fértil',         'Solo preparado: plantar custa menos energia.',            5,  200, 1.6, 0.03),
  ('cost_3a',       'cost',       3, -1, 'cost_2',        'cost',          'Compostagem',         'Restos viram adubo e barateiam o plantio.',               3, 1000, 1.8, 0.05),
  ('cost_3b',       'cost',       3,  1, 'cost_2',        'energy',        'Mochila de Sementes', 'Cada passo rende mais energia.',                          3,  800, 1.8, 0.10),
  ('cost_4',        'cost',       4, -1, 'cost_3a',       'cost',          'Colheita Sagrada',    'Plantar fica muito mais barato.',                         1, 6000, 1.0, 0.15),
  -- Energia
  ('energy_2',      'energy',     2,  0, 'energy_1',      'energy',        'Passada Firme',       'Passos mais firmes geram mais energia.',                  5,  200, 1.6, 0.10),
  ('energy_3a',     'energy',     3, -1, 'energy_2',      'energy',        'Trilha Solar',        'Caminhar sob o sol rende energia extra.',                 3, 1000, 1.8, 0.20),
  ('energy_3b',     'energy',     3,  1, 'energy_2',      'cost',          'Atalho Verde',        'Você gasta menos energia em cada plantio.',               3,  800, 1.8, 0.03),
  ('energy_4',      'energy',     4, -1, 'energy_3a',     'energy',        'Maratona Verde',      'Cada passo vale muito mais energia.',                     1, 6000, 1.0, 0.50),
  -- Noite (offline)
  ('offline_2',     'offline',    2,  0, 'offline_1',     'offline',       'Lua Cheia',           'A luz da lua mantém as árvores produzindo.',              5,  250, 1.6, 0.03),
  ('offline_3a',    'offline',    3, -1, 'offline_2',     'offline_hours', 'Vigília da Lumi',     'A Lumi cuida do planeta por mais 2 horas por nível.',     3, 1000, 1.8, 2.00),
  ('offline_3b',    'offline',    3,  1, 'offline_2',     'growth',        'Estrelas Guias',      'A luz das estrelas acelera o crescimento.',               3,  800, 1.8, 0.03),
  ('offline_4',     'offline',    4, -1, 'offline_3a',    'offline',       'Eclipse Verde',       'Fora do app, as árvores rendem quase como com ele aberto.', 1, 6000, 1.0, 0.10)
) as n;

insert into public.upgrades
  (code, branch, tier, branch_slot, parent_id, category, name, description,
   max_level, base_cost, cost_multiplier, effect)
select n.code, n.branch, n.tier, n.branch_slot, parent.id, n.category, n.name,
       n.description, n.max_level, n.base_cost, n.cost_multiplier, n.effect
from upgrade_nodes_seed n
join public.upgrades parent on parent.code = n.parent_code
where n.tier = 2
on conflict (name) do nothing;

insert into public.upgrades
  (code, branch, tier, branch_slot, parent_id, category, name, description,
   max_level, base_cost, cost_multiplier, effect)
select n.code, n.branch, n.tier, n.branch_slot, parent.id, n.category, n.name,
       n.description, n.max_level, n.base_cost, n.cost_multiplier, n.effect
from upgrade_nodes_seed n
join public.upgrades parent on parent.code = n.parent_code
where n.tier = 3
on conflict (name) do nothing;

insert into public.upgrades
  (code, branch, tier, branch_slot, parent_id, category, name, description,
   max_level, base_cost, cost_multiplier, effect)
select n.code, n.branch, n.tier, n.branch_slot, parent.id, n.category, n.name,
       n.description, n.max_level, n.base_cost, n.cost_multiplier, n.effect
from upgrade_nodes_seed n
join public.upgrades parent on parent.code = n.parent_code
where n.tier = 4
on conflict (name) do nothing;

drop table upgrade_nodes_seed;

-- Pai obrigatório a partir do anel 2.
alter table public.upgrades add constraint upgrades_parent_by_tier
  check (tier is null or (tier = 1) = (parent_id is null));

-- ---------------------------------------------------------------------------
-- Funções de economia ajustadas
-- ---------------------------------------------------------------------------

-- Com a árvore, o desconto máximo de custo e de crescimento sobe para 75%.
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
  select ceil(p_species_cost * (p_planet_base_cost / 10.0) * (1 - least(p_cost_bonus, 0.75)));
$$;

-- Oxigênio base (sem bônus) das árvores prontas entre dois instantes.
create or replace function private.tree_oxygen(
  p_user uuid,
  p_from timestamptz,
  p_to timestamptz
)
returns numeric
language sql
stable
set search_path = ''
as $$
  select coalesce(sum(
           s.oxygen_per_sec
           * greatest(0, extract(epoch from (p_to - greatest(p_from, t.ready_at))))
         ), 0)
  from public.user_trees t
  join public.tree_species s on s.id = t.species_id
  where t.user_id = p_user and t.ready_at < p_to and p_from < p_to;
$$;

revoke all on all functions in schema private from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- RPC: oxigênio do tempo fora do app
-- ---------------------------------------------------------------------------
-- O último minuto conta inteiro (é o mesmo da coleta com o app aberto).
-- O resto conta pela taxa offline: 50% + upgrades, no máximo 100%.
-- O período tem teto de 8 horas + upgrade Vigília da Lumi.
create or replace function public.collect_offline_oxygen()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_now timestamptz := now();
  v_away numeric;
  v_max_seconds numeric;
  v_rate numeric;
  v_start timestamptz;
  v_online_from timestamptz;
  v_gained numeric;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_profile from public.profiles where id = v_user for update;

  v_away := greatest(0, extract(epoch from (v_now - v_profile.last_oxygen_at)));
  v_max_seconds := (8 + private.upgrade_bonus(v_user, 'offline_hours')) * 3600;
  v_rate := least(0.5 + private.upgrade_bonus(v_user, 'offline'), 1.0);

  v_start := greatest(v_profile.last_oxygen_at, v_now - make_interval(secs => v_max_seconds));
  v_online_from := greatest(v_start, v_now - interval '60 seconds');

  v_gained := round(
    (private.tree_oxygen(v_user, v_online_from, v_now)
      + private.tree_oxygen(v_user, v_start, v_online_from) * v_rate)
    * (1 + private.upgrade_bonus(v_user, 'production')),
    2
  );

  update public.profiles
  set oxygen = oxygen + v_gained,
      last_oxygen_at = v_now,
      last_seen = v_now
  where id = v_user
  returning * into v_profile;

  if v_gained > 0 then
    perform private.bump_missions(v_user, 'oxygen_collected', v_gained);
  end if;

  return jsonb_build_object(
    'seconds_away', floor(v_away),
    'seconds_counted', floor(least(v_away, v_max_seconds)),
    'offline_rate', v_rate,
    'oxygen_gained', v_gained,
    'oxygen', v_profile.oxygen
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: plantar (crescimento com teto de 75% e dados do próximo planeta)
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
  v_next public.planets%rowtype;
  v_species public.tree_species%rowtype;
  v_cost numeric;
  v_grow_seconds numeric;
  v_tree public.user_trees%rowtype;
  v_completed boolean := false;
  v_points integer := 0;
  v_achievements jsonb;
  v_next_json jsonb;
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

  -- Crescimento reduz o tempo (máximo de 75%).
  v_grow_seconds := v_species.grow_seconds
    * (1 - least(private.upgrade_bonus(v_user, 'growth'), 0.75));

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

  -- Planeta concluído: marca, dá pontos (100 x ordem) e prepara o próximo.
  if v_user_planet.reforested_slots >= v_planet.total_slots then
    v_completed := true;
    v_points := 100 * v_planet.order_index;
    update public.user_planets set completed_at = now() where id = v_user_planet.id;

    select * into v_next
    from public.planets
    where id = private.planet_for_order(v_planet.order_index + 1);
    v_next_json := jsonb_build_object(
      'order_index', v_next.order_index,
      'name', v_next.name,
      'theme', v_next.theme,
      'total_slots', v_next.total_slots
    );
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
    'planet_completed', v_completed,
    'points_earned', v_points,
    'next_planet', v_next_json,
    'achievements_unlocked', v_achievements
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: comprar upgrade (agora exige o nó pai)
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

  if v_upgrade.parent_id is not null and not exists (
    select 1 from public.user_upgrades
    where user_id = v_user and upgrade_id = v_upgrade.parent_id and level >= 1
  ) then
    raise exception 'upgrade_locked';
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
-- Permissões das RPCs: só usuários logados
-- ---------------------------------------------------------------------------
revoke execute on function
  public.collect_offline_oxygen(),
  public.plant_tree(integer, bigint),
  public.buy_upgrade(bigint)
from public, anon;

grant execute on function
  public.collect_offline_oxygen(),
  public.plant_tree(integer, bigint),
  public.buy_upgrade(bigint)
to authenticated;

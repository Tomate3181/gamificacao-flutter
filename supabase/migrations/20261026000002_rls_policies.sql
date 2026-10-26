-- EcoPlanet: RLS e permissões.
--
-- Regras:
-- - RLS ativo em todas as tabelas.
-- - Catálogos: só leitura para usuários logados.
-- - user_* e profiles: cada usuário só enxerga as próprias linhas.
-- - O cliente não escreve em user_*: tudo passa por funções RPC
--   (security definer) criadas nas próximas fases.
-- - Em profiles, o cliente só pode alterar o próprio apelido.

-- ---------------------------------------------------------------------------
-- Ativa RLS
-- ---------------------------------------------------------------------------
alter table public.profiles          enable row level security;
alter table public.planets           enable row level security;
alter table public.tree_species      enable row level security;
alter table public.upgrades          enable row level security;
alter table public.missions          enable row level security;
alter table public.achievements      enable row level security;
alter table public.user_planets      enable row level security;
alter table public.user_trees        enable row level security;
alter table public.user_upgrades     enable row level security;
alter table public.user_missions     enable row level security;
alter table public.user_achievements enable row level security;

-- ---------------------------------------------------------------------------
-- Permissões de tabela (defesa extra além do RLS)
-- O Supabase concede tudo para anon/authenticated por padrão; aqui tiramos
-- a escrita e deixamos só o que o app precisa.
-- ---------------------------------------------------------------------------
revoke insert, update, delete, truncate on
  public.profiles, public.planets, public.tree_species, public.upgrades,
  public.missions, public.achievements, public.user_planets, public.user_trees,
  public.user_upgrades, public.user_missions, public.user_achievements
from anon, authenticated;

revoke select on
  public.profiles, public.user_planets, public.user_trees,
  public.user_upgrades, public.user_missions, public.user_achievements
from anon;

-- Só o apelido é editável pelo cliente. energy, oxygen, total_points e
-- last_seen ficam bloqueados (mudam só por RPC).
grant update (nickname) on public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
create policy "profiles: ler o próprio"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id);

create policy "profiles: atualizar o próprio"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- ---------------------------------------------------------------------------
-- Catálogos: leitura para quem está logado
-- ---------------------------------------------------------------------------
create policy "planets: leitura autenticada"
  on public.planets for select to authenticated using (true);

create policy "tree_species: leitura autenticada"
  on public.tree_species for select to authenticated using (true);

create policy "upgrades: leitura autenticada"
  on public.upgrades for select to authenticated using (true);

create policy "missions: leitura autenticada"
  on public.missions for select to authenticated using (true);

create policy "achievements: leitura autenticada"
  on public.achievements for select to authenticated using (true);

-- ---------------------------------------------------------------------------
-- user_*: leitura das próprias linhas (escrita só via RPC)
-- ---------------------------------------------------------------------------
create policy "user_planets: ler as próprias"
  on public.user_planets for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "user_trees: ler as próprias"
  on public.user_trees for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "user_upgrades: ler as próprias"
  on public.user_upgrades for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "user_missions: ler as próprias"
  on public.user_missions for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "user_achievements: ler as próprias"
  on public.user_achievements for select to authenticated
  using ((select auth.uid()) = user_id);

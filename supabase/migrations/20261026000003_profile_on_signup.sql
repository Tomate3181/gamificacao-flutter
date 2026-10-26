-- EcoPlanet: cria o perfil automaticamente no cadastro.
--
-- O app envia o apelido em `raw_user_meta_data.nickname`. Se vier vazio ou
-- inválido, usa um apelido padrão para não travar o cadastro.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_nickname text;
begin
  v_nickname := left(btrim(coalesce(new.raw_user_meta_data ->> 'nickname', '')), 20);

  if char_length(v_nickname) < 3 then
    v_nickname := 'Guardião ' || substr(new.id::text, 1, 6);
  end if;

  insert into public.profiles (id, nickname)
  values (new.id, v_nickname);

  return new;
end;
$$;

-- A função só deve rodar pelo trigger, nunca por RPC.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

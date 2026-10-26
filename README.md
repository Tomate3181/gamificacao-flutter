# EcoPlanet

Jogo incremental de reflorestamento: o jogador planta árvores com a energia dos próprios passos, junto com a guardiã Lumi. Feito em Flutter com Supabase (Auth e PostgreSQL com RLS).

O design completo está em [docs/GDD.md](docs/GDD.md).

## Requisitos

- Flutter 3.44 ou mais novo
- Um projeto no [Supabase](https://supabase.com)

## 1. Preparar o Supabase

1. Crie um projeto no Supabase.
2. Aplique as migrations de `supabase/migrations/` **na ordem dos números**. Você pode fazer isso de duas formas:
   - **SQL Editor (mais simples):** abra cada arquivo, cole o conteúdo no SQL Editor do painel e execute.
   - **Supabase CLI:** `supabase init`, depois `supabase link --project-ref SEU_PROJETO` e por fim `supabase db push`.
3. Em *Authentication → Sign In / Providers → Email*, desligue **Confirm email** para facilitar os testes. O app também funciona com a confirmação ligada.

## 2. Configurar as chaves

As chaves **nunca** ficam no código. Elas entram por `--dart-define`.

1. Copie `config/supabase.example.json` para `config/supabase.json`. Esse arquivo está no `.gitignore`.
2. Preencha com os dados de *Project Settings → API*:
   - `SUPABASE_URL`: a URL do projeto.
   - `SUPABASE_ANON_KEY`: a chave **anon** ou **publishable**. Nunca use a `service_role` / `secret`.

## 3. Rodar

No navegador (Chrome):

```bash
flutter run -d chrome --dart-define-from-file=config/supabase.json
```

Em um celular ou emulador Android:

```bash
flutter run --dart-define-from-file=config/supabase.json
```

Também dá para passar as chaves uma a uma:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxx
```

Se o app abrir sem as chaves, ele mostra uma tela explicando o que falta.

## 4. Testes

```bash
flutter analyze
```

```bash
flutter test
```

## Estrutura

```
lib/
├── core/          # config, rotas (GoRouter), tema e validações
├── features/      # uma pasta por feature, com data/, domain/ e presentation/
└── widgets/       # widgets reutilizáveis
supabase/migrations/  # schema, RLS, trigger de perfil e dados iniciais
```

## Segurança

- RLS ativo em todas as tabelas.
- Cada usuário só lê as próprias linhas em `profiles` e `user_*`.
- Energia, oxigênio e pontos não podem ser alterados pelo app: só por funções RPC no banco.

# EcoPlanet

Jogo incremental de reflorestamento: o jogador planta árvores com a energia dos próprios passos, junto com a guardiã Lumi. Feito em Flutter com Supabase (Auth e PostgreSQL com RLS).

O design completo está em [docs/GDD.md](docs/GDD.md).

## Como se joga

- **Caminhe** para ganhar Energia Verde: 100 passos valem 1 de energia.
- **Toque numa região poluída** do planeta e escolha uma espécie para plantar. Cada árvore cresce e passa a gerar **oxigênio**, inclusive com o app fechado.
- **Reflorestou 100%?** O planeta está salvo, você ganha pontos e viaja para o próximo. O primeiro tem 10 regiões; cada planeta seguinte tem 50% a mais (até 200) e custa 30% a mais. O ciclo não tem fim: depois do 5º, os temas voltam com um numeral (*Deserto Esquecido II*).
- **Loja:** uma árvore radial de melhorias com 5 ramos (Produção, Crescimento, Custo, Energia e Noite). Cada nó libera os da frente, e alguns nós cruzam efeitos entre ramos.
- **Fora do app**, as árvores rendem 50% do normal por até 8 horas. O ramo Noite aumenta as duas coisas. Ao voltar, a Lumi mostra quanto oxigênio foi juntado.
- **Missões** de gameplay (caminhar, plantar, coletar, melhorar) dão pontos e energia. Também há **conquistas** e um **ranking global**.

## Requisitos

- Flutter 3.44 ou mais novo
- Um projeto no [Supabase](https://supabase.com)

## 1. Preparar o Supabase

1. Crie um projeto no Supabase.
2. Aplique as migrations de `supabase/migrations/` **na ordem dos números**:

   | Arquivo | O que faz |
   |---|---|
   | `20261026000001_create_tables.sql` | Tabelas |
   | `20261026000002_rls_policies.sql` | RLS em todas as tabelas |
   | `20261026000003_profile_on_signup.sql` | Cria o perfil no cadastro |
   | `20261026000004_seed_catalog.sql` | Planetas, espécies, upgrades, missões e conquistas |
   | `20261027000001_core_economy.sql` | RPCs da economia (passos, plantio, oxigênio, loja) |
   | `20261109000001_gamification.sql` | Missões de gameplay, conquistas e ranking |
   | `20261109000002_polish.sql` | Ciclo infinito de planetas, oxigênio offline e árvore de upgrades |

   Há duas formas de aplicar:
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

### Passos e modo demo

No celular, o pedômetro converte passos em Energia Verde. No navegador e no emulador não há pedômetro: use **Perfil → Simular 500 passos**. Os passos simulados passam pelo mesmo limite do servidor, de 10 passos por segundo acumulados por até 1 hora.

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
└── widgets/       # widgets reutilizáveis (planeta, Lumi, árvore de upgrades, partículas…)
assets/
├── sprites/       # pixel art gerada por script
└── fonts/         # Pixelify Sans (títulos)
supabase/migrations/  # schema, RLS, dados iniciais e RPCs
tool/sprites/         # script que gera os sprites (Python + Pillow)
```

Para regenerar os sprites:

```bash
python tool/sprites/generate_sprites.py
```

## Segurança

- RLS ativo em todas as tabelas.
- Cada usuário só lê as próprias linhas em `profiles` e `user_*`.
- Energia, oxigênio e pontos não podem ser alterados pelo app: só por funções RPC no banco, que validam tudo (limite de passos, custo, nó pai da árvore, teto do tempo offline).
- As chaves do Supabase entram por `--dart-define` e não são versionadas.

## Créditos

- Fonte [Pixelify Sans](https://github.com/eifetx/Pixelify-Sans), licença SIL Open Font License 1.1 (`assets/fonts/OFL.txt`).
- Sprites próprios, gerados por `tool/sprites/generate_sprites.py`.

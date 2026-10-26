# CLAUDE.md: regras do projeto EcoPlanet

Leia antes de qualquer tarefa:
- `docs/GDD.md`: design completo do jogo (fonte da verdade).

## Contexto

- Projeto de atividade de Flutter do curso, em dupla.
- Jogo: EcoPlanet. Guardiã: Lumi.
- Stack: Flutter, GoRouter, Supabase (Auth + PostgreSQL com RLS).

## Regras de código

- Use GoRouter para toda navegação. Nada de `Navigator.push` direto.
- Rotas internas protegidas: usuário não autenticado é redirecionado para `/login`.
- Widgets reutilizáveis ficam em `lib/widgets/` e recebem dados por parâmetro.
- Organize por feature: `lib/features/<nome>/` com `data/`, `domain/` e `presentation/`.
- Nomes de arquivos em `snake_case`, classes em `PascalCase`.
- Sem lógica de negócio na UI. Chamadas ao Supabase ficam na camada `data/`.
- Toda tela que consulta dados precisa de indicador de carregamento, e listas vazias e erros precisam de mensagem.

## Regras de segurança e dados

- **Nunca** altere pontos, energia ou oxigênio direto pelo cliente. Use RPC no Supabase.
- RLS ativo em todas as tabelas. Usuário só acessa as próprias linhas em `user_*` e `profiles`.
- URL e anon key do Supabase vêm de `--dart-define`, nunca hardcoded.
- Não commite chaves, `.env` nem credenciais.
- Migrations ficam em `supabase/migrations/`, numeradas e versionadas.

## Sensores e permissões

- Pedômetro: `pedometer`. Acelerômetro e luz: `sensors_plus`.
- Android: `ACTIVITY_RECOGNITION` no `AndroidManifest.xml`.
- iOS: `NSMotionUsageDescription` no `Info.plist`.
- Sempre ofereça o modo demo ("simular passos") nas configurações, para testes e apresentação.

## Sprites e arte

- Tamanho base: Lumi em 16x16 ou 32x32. Árvores e planeta conforme o GDD.
- Estilo pixel com contorno escuro, paleta definida no GDD (seção 11).
- Antes de gerar muitos sprites, gere um e mostre para validação do estilo.
- Mantenha os sprites em `assets/sprites/` e registre no `pubspec.yaml`.

## Fluxo de trabalho

- Trabalhe por fase do roadmap (seção 17 do GDD). Não pule fases.
- Antes de começar uma fase, mostre o plano de arquivos e espere confirmação.
- Ao terminar uma fase, rode `flutter analyze` e `flutter test`, e liste o que foi feito e o que falta.
- Não implemente progresso offline antes da fase 4.
- Não adicione ranking por turma. O ranking é global.

## Regras de entrega (PDF)

- Repositório público no GitHub.
- `README.md` com instruções para rodar o projeto (incluindo como passar as chaves do Supabase).
- Arquivo `.zip` final contendo **somente** `lib/` e `pubspec.yaml`.
- Data de entrega: 09/11/2026.

## Idioma

- Textos da interface, comentários e README: português do Brasil.
- Nomes de código (variáveis, classes, arquivos): inglês.

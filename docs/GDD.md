# EcoPlanet: GDD (versão consolidada)

Este é o documento de referência do projeto. Ele junta a v0.1 e a v0.2. Em caso de dúvida, este arquivo vale mais que qualquer conversa anterior.

## 1. Visão geral

- **Nome:** EcoPlanet
- **Plataforma:** Flutter (Android e iOS), backend Supabase (Auth + PostgreSQL)
- **Gênero:** incremental / idle com gamificação sustentável
- **Pitch:** o jogador reflorestа planetas poluídos, plantando árvores e gerando energia com os próprios passos. Ao chegar a 100%, o próximo planeta começa. Os upgrades tornam cada planeta mais fácil.
- **Pilares:**
  1. Progresso visível: toda ação muda algo na tela, principalmente o planeta.
  2. Ação real vira jogo: andar é a principal fonte de energia.
  3. Ciclo infinito: sempre existe o próximo planeta.
  4. Sustentabilidade como história, não como lição: as missões do PDF fazem parte do jogo.

## 2. Loop principal

1. Jogador abre o app e vê o planeta atual (imagem fixa, parcialmente visível), com a barra de progresso no topo.
2. Caminha (pedômetro) e ganha **Energia Verde**.
3. Toca em regiões poluídas e gasta energia para plantar árvores. Cada árvore aumenta o % do planeta.
4. Árvores geram **Oxigênio** mesmo com o app fechado (progresso offline fica para o polimento).
5. Completa missões ecológicas para bônus de energia e pontos.
6. Ao chegar a 100%, o planeta é concluído, dá recompensa e libera o próximo.
7. Upgrades reduzem custo, aumentam produção e diminuem o tempo de crescimento.

## 3. Recursos

| Recurso | Fonte | Uso |
|---|---|---|
| Energia Verde | Passos (100 passos = 1), missões, sacudir o celular | Plantar árvores |
| Oxigênio | Árvores plantadas (por segundo) | Comprar upgrades |
| Pontos | Missões concluídas, planetas concluídos | Ranking e conquistas |

## 4. Regiões e planetas

- Planeta é uma **imagem fixa**, dividida em regiões plantáveis (grade de 10x10 = 100 regiões no planeta 1).
- Cada região começa poluída. Plantar transforma a região em verde.
- Progresso do planeta = regiões reflorestadas / total.
- Planetas seguintes: +20% de regiões e +30% de custo base.
- Cada planeta tem tema visual (deserto, floresta, ilha, tundra, montanha).
- Sem fim: o ciclo continua indefinidamente.

## 5. Espécies de árvore (8)

| # | Espécie | Custo (energia) | Oxigênio/s | Crescimento | Raridade | Papel |
|---|---|---|---|---|---|---|
| 1 | Muda | 10 | 1 | 10s | Comum | Início, barata e rápida |
| 2 | Bambu | 25 | 2 | 15s | Comum | Cresce rápido |
| 3 | Carvalho | 60 | 4 | 30s | Incomum | Equilíbrio |
| 4 | Pinheiro | 90 | 5 | 40s | Incomum | Bônus em planetas frios |
| 5 | Cerejeira | 150 | 8 | 60s | Rara | Bônus visual |
| 6 | Mangue | 250 | 12 | 90s | Rara | Bônus em planetas com água |
| 7 | Sequoia | 500 | 25 | 3min | Épica | Alta produção, lenta |
| 8 | Árvore ancestral | 1200 | 60 | 5min | Lendária | Topo da coleção |

Cada espécie tem bônus de planeta, para o jogador trocar de espécie conforme o planeta.

## 6. Upgrades (Loja)

Categorias, cada uma com níveis (1 a 10) e custo crescente (1.5x por nível):

- **Crescimento:** reduz o tempo de crescimento das árvores.
- **Produção:** aumenta o oxigênio gerado.
- **Custo:** reduz a energia para plantar.
- **Automação:** drones que plantam sozinhos.
- **Energia:** aumenta a energia por passo.

Upgrades são permanentes e valem para todos os planetas.

## 7. Missões ecológicas (requisito do PDF)

- **Modo economia:** ficar um período sem iluminação desnecessária.
- **Explorador sustentável:** identificar e registrar um ponto de coleta seletiva.
- **Desafio reutilizar:** dar nova utilidade a um objeto que seria descartado.
- **Mobilidade consciente:** trajeto curto a pé ou de bicicleta, quando seguro e viável.
- **Consumo inteligente:** planejar uma compra evitando desperdícios.

Cada missão: título, descrição, categoria, dificuldade (fácil, média, difícil), pontos e status (disponível, em andamento, concluída). Uma missão só dá pontos uma vez por usuário. Pode ser simulada no protótipo.

## 8. Conquistas

- **Primeiros passos:** concluir a primeira missão.
- **Agente verde:** concluir cinco missões.
- **Consistência:** concluir missões em três dias diferentes.
- **Mestre da reciclagem:** concluir X desafios da categoria.
- **Planeta salvo:** concluir o primeiro planeta.
- **Floresta viva:** plantar 100 árvores.

Conquistas bloqueadas aparecem em cinza, com a condição visível.

## 9. Ranking (global)

- Ordenado pela soma de pontos (missões + planetas concluídos).
- Mostra posição, apelido, pontos e destaque para o top 3.
- Mostra a posição do usuário logado, mesmo fora do top 3.
- Calculado no banco, nunca em lista fixa na interface.

## 10. Lumi (guardiã)

Lumi é a companheira do jogador. É um bichinho pequeno, dourado, inspirado no clima do Allay do Minecraft.

- **Estados:**
  - *Vagando:* anda devagar pela parte visível do planeta, com balanço suave.
  - *Seguindo:* vai até a região tocada pelo jogador e fica ao lado da árvore plantada.
  - *Feliz:* brilha ou pula quando uma árvore termina de crescer ou uma missão é concluída.
  - *Coletando:* solta brilhos que viram oxigênio de forma periódica.
- **Sprite:** 16x16 ou 32x32, 3 a 4 frames por estado. Estilo pixel, contorno escuro.
- **Cor:** dourado, para contrastar com o azul-marinho do céu e o verde do planeta.

## 11. Identidade visual

- **Direção:** céu noturno de planeta esquecido, inspirado no clima do Celeste Farewell, sem cópia.
- **Paleta base:** azul-marinho profundo no céu, aurora em teal, lilás e rosa-quente como acento.
- **Destaque:** dourado para ações e recompensas.
- **Planeta e verdes:** tons saturados que contrastam com o céu escuro.
- **Estilo:** fundo pintado, sprites em pixel, partículas de brilho e folhas.
- **Fontes:** a definir.
- **Logo:** a definir.

## 12. Telas e navegação

| Tela | Rota | Conteúdo |
|---|---|---|
| Splash | `/splash` | Logo, animação, redirecionamento por sessão |
| Login | `/login` | E-mail e senha, erros claros |
| Cadastro | `/register` | E-mail, senha e apelido |
| Home (planeta) | `/home` | Barra de progresso, planeta, Lumi, contadores |
| Missões | `/missions` | Lista ou grade por categoria e status |
| Detalhes da missão | `/missions/:id` | Descrição, orientações, pontos, botão iniciar/concluir |
| Loja | `/shop` | Upgrades por categoria, custo e nível |
| Conquistas | `/achievements` | Grade desbloqueada e bloqueada |
| Ranking | `/ranking` | Lista global, top 3 destacado, posição do usuário |
| Perfil | `/profile` | Apelido, e-mail, pontos, missões, conquistas, planetas, logout e configurações |

- **GoRouter** para todas as rotas, com proteção de rotas internas.
- **Barra inferior flutuante:** Loja, Missões, Ranking e Perfil.
- Navegação não depende só do botão voltar do Android.

## 13. Widgets personalizados (mínimo 3, reutilizáveis)

- `MissionCard`: cartão de missão.
- `ProgressCard`: pontos e progresso do jogador.
- `AchievementBadge`: conquista desbloqueada ou bloqueada.
- `PlanetProgressBar`: barra do planeta no topo.
- `FloatingNavBar`: barra inferior flutuante.
- `UpgradeTile`: item da loja.
- `PlanetView` e `TreeSprite`: planeta e árvores.
- `LumiSprite`: a companheira, com estados.

Todos recebem dados por parâmetros.

## 14. Sensores

| Sensor | Uso | Pacote |
|---|---|---|
| Pedômetro | Energia por passos | `pedometer` |
| Acelerômetro | Sacudir para bônus | `sensors_plus` |
| Luz ambiente (Android) | Bônus de economia de energia | `sensors_plus` |

- **Permissões:** Android `ACTIVITY_RECOGNITION` no `AndroidManifest.xml`; iOS `NSMotionUsageDescription` no `Info.plist`.
- **Modo demo:** botão "simular passos" nas configurações, para testes em emulador e para a apresentação.

## 15. Backend (Supabase)

### Tabelas

| Tabela | Campos principais |
|---|---|
| `profiles` | id (= auth.uid), nickname, energy, oxygen, total_points, last_seen |
| `planets` | id, order_index, name, theme, total_slots, base_cost |
| `user_planets` | id, user_id, planet_id, reforested_slots, completed_at |
| `tree_species` | id, name, cost, oxygen_per_sec, grow_seconds, rarity |
| `user_trees` | id, user_id, user_planet_id, species_id, slot_index, planted_at |
| `upgrades` | id, category, name, max_level, base_cost, effect |
| `user_upgrades` | user_id, upgrade_id, level |
| `missions` | id, title, description, category, difficulty, points |
| `user_missions` | user_id, mission_id, status, completed_at |
| `achievements` | id, name, description, icon, condition_type, condition_value |
| `user_achievements` | user_id, achievement_id, unlocked_at |

### Segurança (requisito do PDF)

- RLS ativo em todas as tabelas.
- Usuário só lê e escreve as próprias linhas em `user_*` e `profiles`.
- Energia, oxigênio e pontos **não** são alterados direto pelo cliente. Ações passam por funções RPC que validam no servidor: `plant_tree`, `complete_mission`, `buy_upgrade`, `collect_offline_oxygen` (esta última na fase de polimento).
- `user_missions` com constraint única `(user_id, mission_id)`, para não dar pontos repetidos.
- Ranking vem de view ou função que calcula a pontuação a partir do banco.

## 16. Economia inicial (para balancear depois)

- 100 passos = 1 energia.
- Muda custa 10 energia.
- Upgrade nível 1: 50 oxigênio, cresce 1.5x por nível.
- Planeta 1 deve levar cerca de 15 a 30 minutos de jogo ativo.

## 17. Roadmap

1. **Fase 1, base:** projeto Flutter, GoRouter, tema visual, Auth com Supabase, tabelas e RLS.
2. **Fase 2, núcleo:** tela do planeta com plantio por toque, barra de progresso, energia por passos (ou simulação), Lumi em estados básicos, loja com 2 ou 3 upgrades, RPCs `plant_tree` e `buy_upgrade`.
3. **Fase 3, gamificação:** missões (lista, detalhes, conclusão única), conquistas, ranking global e perfil.
4. **Fase 4, polimento:** identidade visual final, sprites completos, oxigênio idle e progresso offline, ciclo de planetas, efeitos visuais, modo demo, README.

## 18. Requisitos do curso (checklist)

- [ ] Splash com logo e redirecionamento por auth
- [ ] Login e cadastro com Supabase Auth, erros claros
- [ ] Home com saudação, pontos, missões concluídas, missão em destaque, lista e progresso
- [ ] Detalhes da missão com parâmetro pela rota
- [ ] Conquistas com bloqueio e condição
- [ ] Ranking global do banco, top 3 destacado e posição do usuário
- [ ] Perfil com dados e logout
- [ ] GoRouter com proteção de rotas
- [ ] 3 ou mais widgets personalizados reutilizáveis
- [ ] PostgreSQL via Supabase com RLS
- [ ] Indicadores de carregamento e mensagens para listas vazias e erros
- [ ] Atualização visual após concluir missão

## 19. Pontos em aberto

- Nome final da fonte e logo.
- Pipeline de sprites (SpriteCook ou outro) e paleta final.
- Balanceamento da economia, validado na prática.

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
4. Árvores geram **Oxigênio** mesmo com o app fechado: fora do app rendem 50% por até 8 horas (o ramo Noite da loja melhora as duas coisas).
5. Completa missões ecológicas para bônus de energia e pontos.
6. Ao chegar a 100%, o planeta é concluído, dá recompensa e libera o próximo.
7. A árvore de upgrades reduz custo, aumenta produção e energia, diminui o tempo de crescimento e melhora o rendimento offline.

## 3. Recursos

| Recurso | Fonte | Uso |
|---|---|---|
| Energia Verde | Passos (100 passos = 1), missões, sacudir o celular | Plantar árvores |
| Oxigênio | Árvores plantadas (por segundo) | Comprar upgrades |
| Pontos | Missões concluídas, planetas concluídos | Ranking e conquistas |

## 4. Regiões e planetas

- Planeta é uma **imagem fixa**, dividida em regiões plantáveis numa grade quase quadrada.
- Decisão de 09/11/2026 (fase 4): o planeta 1 começa pequeno, com **10 regiões**. Cada planeta seguinte tem **+50% de regiões** (teto de 200) e **+30% de custo base**: 10, 15, 23, 34, 51, 76…
- Cada região começa poluída. Plantar transforma a região em verde.
- Progresso do planeta = regiões reflorestadas / total. Ao chegar em 100%: +100 pontos x número do planeta e viagem para o próximo.
- Cada planeta tem tema visual (deserto, floresta, ilha, tundra, montanha).
- Sem fim: depois do 5º planeta o servidor cria o próximo, com os temas em ciclo e numeral no nome (*Deserto Esquecido II*).

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

## 6. Upgrades (Loja): árvore radial

Decisão de 09/11/2026 (fase 4): a loja virou uma **árvore radial**. A Lumi fica no centro e 5 ramos saem dela, a cada 72 graus. Cada ramo tem 4 anéis e 5 nós:

- Anel 1: raiz do ramo (5 níveis).
- Anel 2: reforço da raiz (5 níveis).
- Anel 3: dois nós, um que aprofunda o ramo e outro que **cruza** com outro efeito (3 níveis cada).
- Anel 4: nó final, caro e forte (1 nível).

Um nó só pode ser comprado quando o **pai tem pelo menos 1 nível**, e o servidor confere isso. O custo cresce por nível (1,5x a 1,8x).

| Ramo | Efeito principal | Nó que cruza |
|---|---|---|
| Produção | +% oxigênio | Orvalho Noturno (offline) |
| Crescimento | -% tempo de crescimento | Seiva Doce (produção) |
| Custo | -% energia para plantar | Mochila de Sementes (energia) |
| Energia | +% energia por passo | Atalho Verde (custo) |
| Noite | +% rendimento offline | Estrelas Guias (crescimento) e Vigília da Lumi (+2 h de coleta offline por nível) |

- O efeito de cada categoria é a soma de todos os nós dela, de qualquer ramo.
- Tetos: custo e crescimento até -75%; rendimento offline até 100%.
- **Automação** (drones) ficou fora da árvore.
- Upgrades são permanentes e valem para todos os planetas.

## 7. Missões (gameplay)

Decisão de 09/11/2026: as missões são objetivos do próprio jogo, não tarefas fora dele. Nada de foto ou comprovação: o progresso é contado pelo servidor enquanto a pessoa joga.

Categorias:

- **Caminhada:** dar X passos (pedômetro ou modo demo).
- **Plantio:** plantar X árvores, ou X árvores de uma espécie.
- **Oxigênio:** coletar X de oxigênio.
- **Melhorias:** comprar upgrades na loja.

Fluxo: o jogador **inicia** a missão, o progresso conta a partir daí (dentro das RPCs de passos, plantio, coleta e compra) e, ao chegar na meta, ele **resgata** a recompensa de pontos e energia (fácil 20, média 35, difícil 50 de energia).

Cada missão: título, descrição, dica, categoria, dificuldade (fácil, média, difícil), meta, pontos, energia e status (disponível, em andamento, pronta para resgatar, concluída). Uma missão só dá recompensa uma vez por usuário. O catálogo inicial tem 10 missões; o balanceamento fica para depois que a base do jogo estiver completa.

## 8. Conquistas

- **Primeiros passos:** concluir a primeira missão.
- **Agente verde:** concluir cinco missões.
- **Consistência:** concluir missões em três dias diferentes.
- **Mestre jardineiro:** concluir três missões de plantio (substitui "Mestre da reciclagem").
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
- **Fontes:** Pixelify Sans (licença OFL) nos títulos grandes. Números, botões e texto corrido usam a fonte padrão, para a leitura ficar clara.
- **Logo:** planeta meio reflorestado e meio poluído, com uma muda no topo, anel de aurora e a Lumi (48x48, gerado pelo script de sprites).

## 12. Telas e navegação

| Tela | Rota | Conteúdo |
|---|---|---|
| Splash | `/splash` | Logo, animação, redirecionamento por sessão |
| Login | `/login` | E-mail e senha, erros claros |
| Cadastro | `/register` | E-mail, senha e apelido |
| Home (planeta) | `/home` | Barra de progresso, planeta, Lumi, contadores |
| Missões | `/missions` | Lista ou grade por categoria e status |
| Detalhes da missão | `/missions/:id` | Objetivo, dica, recompensa, progresso, botão iniciar/resgatar |
| Loja | `/shop` | Upgrades por categoria, custo e nível |
| Conquistas | `/achievements` | Grade desbloqueada e bloqueada |
| Ranking | `/ranking` | Lista global, top 3 destacado, posição do usuário |
| Perfil | `/profile` | Apelido, e-mail, pontos, missões, conquistas, planetas, logout e configurações |

- **GoRouter** para todas as rotas, com proteção de rotas internas.
- **Barra inferior flutuante:** Planeta, Missões, Loja, Ranking e Perfil. Conquistas abrem a partir do perfil.
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
| `missions` | id, title, description, guidance, category, difficulty, points, energy_reward, goal_type, goal_value, goal_species_id |
| `user_missions` | user_id, mission_id, status, progress, completed_at |
| `achievements` | id, name, description, icon, condition_type, condition_value |
| `user_achievements` | user_id, achievement_id, unlocked_at |

### Segurança (requisito do PDF)

- RLS ativo em todas as tabelas.
- Usuário só lê e escreve as próprias linhas em `user_*` e `profiles`.
- Energia, oxigênio e pontos **não** são alterados direto pelo cliente. Ações passam por funções RPC que validam no servidor: `plant_tree`, `buy_upgrade`, `add_step_energy`, `collect_oxygen`, `collect_offline_oxygen`, `start_mission`, `complete_mission`.
- Conquistas são desbloqueadas no servidor ao plantar e ao resgatar missões.
- `user_missions` com constraint única `(user_id, mission_id)`, para não dar pontos repetidos.
- Ranking vem de view ou função que calcula a pontuação a partir do banco.

## 16. Economia inicial (para balancear depois)

- 100 passos = 1 energia.
- Muda custa 10 energia.
- Raízes da árvore de upgrades: 50 oxigênio no nível 1, crescendo 1,5x por nível.
- Planeta 1 tem 10 regiões: dá para concluir na primeira sessão e já ver a viagem para o próximo.
- Oxigênio offline: 50% do normal, por até 8 horas (melhorável no ramo Noite).

## 17. Roadmap

1. **Fase 1, base:** projeto Flutter, GoRouter, tema visual, Auth com Supabase, tabelas e RLS.
2. **Fase 2, núcleo:** tela do planeta com plantio por toque, barra de progresso, energia por passos (ou simulação), Lumi em estados básicos, loja com 2 ou 3 upgrades, RPCs `plant_tree` e `buy_upgrade`.
3. **Fase 3, gamificação:** missões (lista, detalhes, conclusão única), conquistas, ranking global e perfil.
4. **Fase 4, polimento:** identidade visual final, sprites completos, oxigênio idle e progresso offline, ciclo de planetas, efeitos visuais, modo demo, README. Também entrou a árvore radial de upgrades.

## 18. Requisitos do curso (checklist)

- [x] Splash com logo e redirecionamento por auth
- [x] Login e cadastro com Supabase Auth, erros claros
- [x] Home com saudação, pontos, missões concluídas, missão em destaque, lista e progresso
- [x] Detalhes da missão com parâmetro pela rota
- [x] Conquistas com bloqueio e condição
- [x] Ranking global do banco, top 3 destacado e posição do usuário
- [x] Perfil com dados e logout
- [x] GoRouter com proteção de rotas
- [x] 3 ou mais widgets personalizados reutilizáveis
- [x] PostgreSQL via Supabase com RLS
- [x] Indicadores de carregamento e mensagens para listas vazias e erros
- [x] Atualização visual após concluir missão

## 19. Pontos em aberto

- Balanceamento da economia, validado na prática (missões, custos da árvore, ritmo dos planetas).
- Refinar a árvore de upgrades: mais nós, nós com efeitos novos, talvez Automação.
- Sensores extras do GDD (sacudir o celular, luz ambiente) ficaram fora do escopo.

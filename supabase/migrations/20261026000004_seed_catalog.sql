-- EcoPlanet: dados iniciais dos catálogos (GDD, seções 4 a 8 e 16).
-- Valores de economia são o ponto de partida; o balanceamento vem depois.

-- Planetas: +20% de regiões e +30% de custo base a cada planeta.
insert into public.planets (order_index, name, theme, total_slots, base_cost) values
  (1, 'Deserto Esquecido',   'desert',   100, 10.00),
  (2, 'Floresta Adormecida', 'forest',   120, 13.00),
  (3, 'Arquipélago Turvo',   'island',   144, 16.90),
  (4, 'Tundra Silenciosa',   'tundra',   173, 21.97),
  (5, 'Picos Cinzentos',     'mountain', 207, 28.56)
on conflict (order_index) do nothing;

-- Espécies de árvore (seção 5).
insert into public.tree_species (name, cost, oxygen_per_sec, grow_seconds, rarity, bonus_theme) values
  ('Muda',              10,  1,  10, 'common',    null),
  ('Bambu',             25,  2,  15, 'common',    null),
  ('Carvalho',          60,  4,  30, 'uncommon',  null),
  ('Pinheiro',          90,  5,  40, 'uncommon',  'tundra'),
  ('Cerejeira',        150,  8,  60, 'rare',      null),
  ('Mangue',           250, 12,  90, 'rare',      'island'),
  ('Sequoia',          500, 25, 180, 'epic',      null),
  ('Árvore ancestral', 1200, 60, 300, 'legendary', null)
on conflict (name) do nothing;

-- Upgrades (seção 6): nível 1 custa 50 de oxigênio, 1.5x por nível.
insert into public.upgrades (category, name, description, max_level, base_cost, cost_multiplier, effect) values
  ('growth',     'Adubo Estelar',       'Reduz o tempo de crescimento das árvores.', 10, 50, 1.5, 0.05),
  ('production', 'Fotossíntese Turbo',  'Aumenta o oxigênio gerado pelas árvores.',  10, 50, 1.5, 0.10),
  ('cost',       'Sementes Eficientes', 'Reduz a energia necessária para plantar.',  10, 50, 1.5, 0.05),
  ('automation', 'Drones Plantadores',  'Drones que plantam mudas sozinhos.',        10, 50, 1.5, 1.00),
  ('energy',     'Tênis Verde',         'Aumenta a energia ganha por passo.',        10, 50, 1.5, 0.10)
on conflict (name) do nothing;

-- Missões ecológicas (seção 7).
insert into public.missions (title, description, guidance, category, difficulty, points) values
  (
    'Modo economia',
    'Fique um período sem iluminação desnecessária.',
    'Apague as luzes dos cômodos vazios e aproveite a luz natural por pelo menos 1 hora.',
    'energy_saving', 'easy', 50
  ),
  (
    'Explorador sustentável',
    'Identifique e registre um ponto de coleta seletiva.',
    'Procure um ecoponto ou lixeira de coleta seletiva perto de você e anote onde ele fica.',
    'recycling', 'medium', 80
  ),
  (
    'Desafio reutilizar',
    'Dê uma nova utilidade a um objeto que seria descartado.',
    'Escolha um pote, garrafa ou caixa e transforme em algo útil, como um vaso ou organizador.',
    'reuse', 'medium', 80
  ),
  (
    'Mobilidade consciente',
    'Faça um trajeto curto a pé ou de bicicleta.',
    'Troque um trajeto curto de carro por caminhada ou bicicleta, só quando for seguro e viável.',
    'mobility', 'easy', 60
  ),
  (
    'Consumo inteligente',
    'Planeje uma compra evitando desperdícios.',
    'Antes de comprar, faça uma lista, confira o que já tem em casa e evite embalagens extras.',
    'conscious_consumption', 'hard', 100
  )
on conflict (title) do nothing;

-- Conquistas (seção 8).
insert into public.achievements (code, name, description, icon, condition_type, condition_value, condition_category) values
  ('first_steps',      'Primeiros passos',     'Conclua sua primeira missão.',              'footprints', 'missions_completed', 1,   null),
  ('green_agent',      'Agente verde',         'Conclua cinco missões.',                    'leaf',       'missions_completed', 5,   null),
  ('consistency',      'Consistência',         'Conclua missões em três dias diferentes.',  'calendar',   'mission_days',       3,   null),
  ('recycling_master', 'Mestre da reciclagem', 'Conclua três desafios de reciclagem.',      'recycle',    'category_missions',  3,   'recycling'),
  ('planet_saved',     'Planeta salvo',        'Conclua o primeiro planeta.',               'planet',     'planets_completed',  1,   null),
  ('living_forest',    'Floresta viva',        'Plante 100 árvores.',                       'forest',     'trees_planted',      100, null)
on conflict (code) do nothing;

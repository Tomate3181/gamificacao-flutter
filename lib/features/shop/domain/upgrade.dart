import '../../player/domain/economy.dart';

/// Efeito de um upgrade. Cada categoria soma o bônus de todos os nós dela.
enum UpgradeCategory {
  growth('growth'),
  production('production'),
  cost('cost'),
  automation('automation'),
  energy('energy'),

  /// Rendimento do oxigênio com o app fechado.
  offline('offline'),

  /// Horas extras de coleta com o app fechado.
  offlineHours('offline_hours');

  const UpgradeCategory(this.dbName);

  /// Valor da coluna `upgrades.category`.
  final String dbName;

  static UpgradeCategory fromName(String name) =>
      values.firstWhere((value) => value.dbName == name);
}

/// Ramo da árvore radial, em sentido horário a partir do topo.
enum UpgradeBranch {
  production,
  growth,
  cost,
  energy,
  offline;

  static UpgradeBranch fromName(String name) =>
      values.firstWhere((value) => value.name == name);
}

/// Nó da árvore de upgrades junto com o nível atual do jogador.
class ShopItem {
  const ShopItem({
    required this.id,
    required this.category,
    required this.branch,
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
    required this.costMultiplier,
    required this.effect,
    required this.level,
    this.tier = 1,
    this.branchSlot = 0,
    this.parentId,
  });

  final int id;
  final UpgradeCategory category;
  final UpgradeBranch branch;
  final String name;
  final String description;
  final int maxLevel;
  final double baseCost;
  final double costMultiplier;

  /// Efeito por nível (0.05 = 5%; em offlineHours, horas).
  final double effect;
  final int level;

  /// Anel da árvore: 1 perto do centro, 4 na ponta.
  final int tier;

  /// Posição no ramo: -1 esquerda, 0 centro, 1 direita.
  final int branchSlot;

  /// Nó que precisa de pelo menos 1 nível antes deste (null na raiz).
  final int? parentId;

  bool get isMaxed => level >= maxLevel;
  bool get isOwned => level > 0;

  /// Bônus total atual (nível x efeito).
  double get bonus => level * effect;

  double get nextCost => Economy.upgradeCost(
    baseCost: baseCost,
    multiplier: costMultiplier,
    currentLevel: level,
  );

  ShopItem withLevel(int newLevel) => ShopItem(
    id: id,
    category: category,
    branch: branch,
    name: name,
    description: description,
    maxLevel: maxLevel,
    baseCost: baseCost,
    costMultiplier: costMultiplier,
    effect: effect,
    level: newLevel,
    tier: tier,
    branchSlot: branchSlot,
    parentId: parentId,
  );
}

/// Situação de um nó para o jogador.
enum UpgradeNodeStatus { locked, available, owned, maxed }

/// A árvore inteira. Regra igual à do servidor (buy_upgrade): um nó só
/// libera quando o pai tem pelo menos 1 nível.
class UpgradeTree {
  UpgradeTree(this.items) : _byId = {for (final item in items) item.id: item};

  final List<ShopItem> items;
  final Map<int, ShopItem> _byId;

  ShopItem? byId(int id) => _byId[id];

  ShopItem? parentOf(ShopItem item) {
    final parentId = item.parentId;
    return parentId == null ? null : _byId[parentId];
  }

  bool isUnlocked(ShopItem item) {
    final parent = parentOf(item);
    return parent == null || parent.isOwned;
  }

  UpgradeNodeStatus statusOf(ShopItem item) {
    if (!isUnlocked(item)) return UpgradeNodeStatus.locked;
    if (item.isMaxed) return UpgradeNodeStatus.maxed;
    if (item.isOwned) return UpgradeNodeStatus.owned;
    return UpgradeNodeStatus.available;
  }

  /// Bônus somado de uma categoria (todos os ramos).
  double bonus(UpgradeCategory category) => items
      .where((item) => item.category == category)
      .fold(0.0, (sum, item) => sum + item.bonus);

  /// Níveis comprados / níveis possíveis.
  int get ownedLevels => items.fold(0, (sum, item) => sum + item.level);
  int get totalLevels => items.fold(0, (sum, item) => sum + item.maxLevel);

  /// Nó sugerido ao abrir a loja: o mais barato que dá para melhorar.
  ShopItem? suggested() {
    final open =
        items.where((item) => isUnlocked(item) && !item.isMaxed).toList()
          ..sort((a, b) => a.nextCost.compareTo(b.nextCost));
    return open.isEmpty ? (items.isEmpty ? null : items.first) : open.first;
  }
}

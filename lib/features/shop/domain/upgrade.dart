import '../../player/domain/economy.dart';

/// Categorias de upgrade (seção 6 do GDD).
enum UpgradeCategory {
  growth,
  production,
  cost,
  automation,
  energy;

  static UpgradeCategory fromName(String name) =>
      values.firstWhere((value) => value.name == name);
}

/// Upgrade da loja junto com o nível atual do jogador.
class ShopItem {
  const ShopItem({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
    required this.costMultiplier,
    required this.effect,
    required this.level,
  });

  final int id;
  final UpgradeCategory category;
  final String name;
  final String description;
  final int maxLevel;
  final double baseCost;
  final double costMultiplier;

  /// Efeito por nível (0.05 = 5%).
  final double effect;
  final int level;

  bool get isMaxed => level >= maxLevel;

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
    name: name,
    description: description,
    maxLevel: maxLevel,
    baseCost: baseCost,
    costMultiplier: costMultiplier,
    effect: effect,
    level: newLevel,
  );
}

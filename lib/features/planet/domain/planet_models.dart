/// Planeta do catálogo.
class Planet {
  const Planet({
    required this.id,
    required this.orderIndex,
    required this.name,
    required this.theme,
    required this.totalSlots,
    required this.baseCost,
  });

  final int id;
  final int orderIndex;
  final String name;
  final String theme;
  final int totalSlots;
  final double baseCost;
}

/// Espécie de árvore do catálogo (seção 5 do GDD).
class TreeSpecies {
  const TreeSpecies({
    required this.id,
    required this.name,
    required this.cost,
    required this.oxygenPerSec,
    required this.growSeconds,
    required this.rarity,
  });

  final int id;
  final String name;
  final int cost;
  final double oxygenPerSec;
  final int growSeconds;
  final String rarity;
}

/// Árvore plantada numa região do planeta.
class PlantedTree {
  const PlantedTree({
    required this.id,
    required this.speciesId,
    required this.slotIndex,
    required this.plantedAt,
    required this.readyAt,
  });

  final String id;
  final int speciesId;
  final int slotIndex;
  final DateTime plantedAt;
  final DateTime readyAt;

  bool isGrown(DateTime now) => !now.isBefore(readyAt);

  /// Progresso do crescimento, de 0 a 1.
  double growth(DateTime now) {
    final total = readyAt.difference(plantedAt).inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = now.difference(plantedAt).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

/// Estado do planeta atual do jogador.
class PlanetState {
  const PlanetState({
    required this.userPlanetId,
    required this.planet,
    required this.reforestedSlots,
    required this.isCompleted,
    required this.trees,
    required this.species,
  });

  final String userPlanetId;
  final Planet planet;
  final int reforestedSlots;
  final bool isCompleted;

  /// Árvores por índice de região.
  final Map<int, PlantedTree> trees;
  final List<TreeSpecies> species;

  double get progress =>
      planet.totalSlots == 0 ? 0 : reforestedSlots / planet.totalSlots;

  TreeSpecies? speciesById(int id) {
    for (final item in species) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool hasGrowingTrees(DateTime now) =>
      trees.values.any((tree) => !tree.isGrown(now));

  PlanetState withPlantedTree(
    PlantedTree tree, {
    required int reforestedSlots,
    required bool isCompleted,
  }) {
    return PlanetState(
      userPlanetId: userPlanetId,
      planet: planet,
      reforestedSlots: reforestedSlots,
      isCompleted: isCompleted,
      trees: {...trees, tree.slotIndex: tree},
      species: species,
    );
  }
}

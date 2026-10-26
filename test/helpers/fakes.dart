import 'package:ecoplanet/core/errors/game_failure.dart';
import 'package:ecoplanet/features/auth/presentation/session_providers.dart';
import 'package:ecoplanet/features/planet/data/planet_repository.dart';
import 'package:ecoplanet/features/planet/domain/planet_models.dart';
import 'package:ecoplanet/features/player/data/player_repository.dart';
import 'package:ecoplanet/features/player/domain/player_stats.dart';
import 'package:ecoplanet/features/shop/data/shop_repository.dart';
import 'package:ecoplanet/features/shop/domain/upgrade.dart';
import 'package:ecoplanet/features/steps/data/pedometer_source.dart';
import 'package:ecoplanet/features/steps/data/step_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

const testUserId = 'user-1';

class FakePlayerRepository implements PlayerRepository {
  PlayerStats stats = const PlayerStats(
    nickname: 'Lumi Fã',
    energy: 50,
    oxygen: 80,
    totalPoints: 0,
  );

  @override
  Future<PlayerStats> fetchStats(String userId) async => stats;

  @override
  Future<({double collected, double oxygen})> collectOxygen() async =>
      (collected: 0.0, oxygen: stats.oxygen);
}

class FakePlanetRepository implements PlanetRepository {
  final plantCalls = <(int, int)>[];
  GameFailure? plantFailure;

  static const species = [
    TreeSpecies(
      id: 1,
      name: 'Muda',
      cost: 10,
      oxygenPerSec: 1,
      growSeconds: 10,
      rarity: 'common',
    ),
    TreeSpecies(
      id: 2,
      name: 'Bambu',
      cost: 25,
      oxygenPerSec: 2,
      growSeconds: 15,
      rarity: 'common',
    ),
  ];

  @override
  Future<PlanetState> fetchCurrent(String userId) async => const PlanetState(
    userPlanetId: 'up-1',
    planet: Planet(
      id: 1,
      orderIndex: 1,
      name: 'Deserto Esquecido',
      theme: 'desert',
      totalSlots: 100,
      baseCost: 10,
    ),
    reforestedSlots: 0,
    isCompleted: false,
    trees: {},
    species: species,
  );

  @override
  Future<PlantResult> plantTree({
    required int slotIndex,
    required int speciesId,
  }) async {
    plantCalls.add((slotIndex, speciesId));
    if (plantFailure != null) throw plantFailure!;
    final now = DateTime.now();
    return (
      tree: PlantedTree(
        id: 't-$slotIndex',
        speciesId: speciesId,
        slotIndex: slotIndex,
        plantedAt: now,
        readyAt: now.add(const Duration(seconds: 10)),
      ),
      energy: 40.0,
      totalPoints: 0,
      reforestedSlots: plantCalls.length,
      planetCompleted: false,
    );
  }
}

class FakeShopRepository implements ShopRepository {
  final buyCalls = <int>[];

  List<ShopItem> items = const [
    ShopItem(
      id: 3,
      category: UpgradeCategory.cost,
      name: 'Sementes Eficientes',
      description: 'Reduz a energia necessária para plantar.',
      maxLevel: 10,
      baseCost: 50,
      costMultiplier: 1.5,
      effect: 0.05,
      level: 0,
    ),
  ];

  @override
  Future<List<ShopItem>> fetchItems(String userId) async => items;

  @override
  Future<({int level, double oxygen})> buy(int upgradeId) async {
    buyCalls.add(upgradeId);
    return (level: 1, oxygen: 30.0);
  }
}

class FakeStepRepository implements StepRepository {
  int acceptLimit = 1 << 30;

  @override
  Future<StepSyncResult> sendSteps(int steps) async {
    final accepted = steps < acceptLimit ? steps : acceptLimit;
    return (
      acceptedSteps: accepted,
      energyGained: accepted / 100,
      energy: 50 + accepted / 100,
    );
  }
}

class UnsupportedStepSensor implements StepSensor {
  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Stream<int> get cumulativeSteps => const Stream.empty();
}

/// Overrides para testar as telas do jogo sem Supabase.
List<Override> gameOverrides({
  FakePlayerRepository? player,
  FakePlanetRepository? planet,
  FakeShopRepository? shop,
  FakeStepRepository? steps,
}) {
  return [
    currentUserIdProvider.overrideWith((ref) => Stream.value(testUserId)),
    playerRepositoryProvider.overrideWithValue(
      player ?? FakePlayerRepository(),
    ),
    planetRepositoryProvider.overrideWithValue(
      planet ?? FakePlanetRepository(),
    ),
    shopRepositoryProvider.overrideWithValue(shop ?? FakeShopRepository()),
    stepRepositoryProvider.overrideWithValue(steps ?? FakeStepRepository()),
    stepSensorProvider.overrideWithValue(UnsupportedStepSensor()),
  ];
}

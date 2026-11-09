import 'package:ecoplanet/core/errors/game_failure.dart';
import 'package:ecoplanet/features/achievements/domain/achievement.dart';
import 'package:ecoplanet/features/achievements/data/achievement_repository.dart';
import 'package:ecoplanet/features/auth/presentation/session_providers.dart';
import 'package:ecoplanet/features/missions/data/mission_repository.dart';
import 'package:ecoplanet/features/missions/domain/mission.dart';
import 'package:ecoplanet/features/planet/data/planet_repository.dart';
import 'package:ecoplanet/features/planet/domain/planet_models.dart';
import 'package:ecoplanet/features/player/data/player_repository.dart';
import 'package:ecoplanet/features/player/domain/player_stats.dart';
import 'package:ecoplanet/features/profile/data/profile_repository.dart';
import 'package:ecoplanet/features/profile/domain/profile_summary.dart';
import 'package:ecoplanet/features/ranking/data/ranking_repository.dart';
import 'package:ecoplanet/features/ranking/domain/ranking_entry.dart';
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
      achievements: const <UnlockedAchievement>[],
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

class FakeMissionRepository implements MissionRepository {
  final startCalls = <int>[];
  final claimCalls = <int>[];
  GameFailure? claimFailure;

  List<MissionView> missions = const [
    MissionView(
      id: 1,
      title: 'Aquecendo',
      description: 'Caminhe 200 passos.',
      guidance: 'Use o modo demo.',
      category: MissionCategory.walking,
      difficulty: MissionDifficulty.easy,
      points: 30,
      energyReward: 20,
      goalValue: 200,
      sortOrder: 1,
      started: true,
      progress: 200,
    ),
    MissionView(
      id: 2,
      title: 'Primeira semente',
      description: 'Plante sua primeira árvore.',
      guidance: 'Toque numa região poluída.',
      category: MissionCategory.planting,
      difficulty: MissionDifficulty.easy,
      points: 20,
      energyReward: 20,
      goalValue: 1,
      sortOrder: 2,
    ),
    MissionView(
      id: 3,
      title: 'Trilha verde',
      description: 'Caminhe 1.000 passos.',
      guidance: 'Cada 100 passos viram 1 de energia.',
      category: MissionCategory.walking,
      difficulty: MissionDifficulty.medium,
      points: 60,
      energyReward: 35,
      goalValue: 1000,
      sortOrder: 6,
      started: true,
      progress: 150,
    ),
  ];

  @override
  Future<List<MissionView>> fetchMissions(String userId) async => missions;

  @override
  Future<double> start(int missionId) async {
    startCalls.add(missionId);
    return 0;
  }

  @override
  Future<MissionClaim> claim(int missionId) async {
    claimCalls.add(missionId);
    if (claimFailure != null) throw claimFailure!;
    return const MissionClaim(
      pointsEarned: 30,
      energyEarned: 20,
      totalPoints: 30,
      energy: 70,
      achievements: [
        UnlockedAchievement(
          id: 1,
          name: 'Primeiros passos',
          icon: 'footprints',
        ),
      ],
    );
  }
}

class FakeAchievementRepository implements AchievementRepository {
  @override
  Future<List<Achievement>> fetchAll(String userId) async => [
    Achievement(
      id: 1,
      code: 'first_steps',
      name: 'Primeiros passos',
      description: 'Conclua sua primeira missão.',
      icon: 'footprints',
      unlockedAt: DateTime(2026, 11, 9),
    ),
    const Achievement(
      id: 2,
      code: 'green_agent',
      name: 'Agente verde',
      description: 'Conclua cinco missões.',
      icon: 'leaf',
    ),
  ];
}

class FakeRankingRepository implements RankingRepository {
  List<RankingEntry> rows = const [
    RankingEntry(position: 1, nickname: 'Bia', totalPoints: 500, isMe: false),
    RankingEntry(position: 2, nickname: 'Caio', totalPoints: 300, isMe: false),
    RankingEntry(position: 3, nickname: 'Duda', totalPoints: 200, isMe: false),
    RankingEntry(position: 4, nickname: 'Eva', totalPoints: 100, isMe: false),
    RankingEntry(position: 9, nickname: 'Lumi Fã', totalPoints: 10, isMe: true),
  ];

  @override
  Future<RankingBoard> fetchRanking({int limit = 50}) async =>
      RankingBoard(rows, limit: 4);
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<ProfileSummary> fetchSummary(String userId) async =>
      const ProfileSummary(
        missionsCompleted: 2,
        achievementsUnlocked: 1,
        achievementsTotal: 6,
        planetsCompleted: 0,
        treesPlanted: 7,
      );
}

/// Overrides para testar as telas do jogo sem Supabase.
List<Override> gameOverrides({
  FakePlayerRepository? player,
  FakePlanetRepository? planet,
  FakeShopRepository? shop,
  FakeStepRepository? steps,
  FakeMissionRepository? missions,
  FakeRankingRepository? ranking,
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
    missionRepositoryProvider.overrideWithValue(
      missions ?? FakeMissionRepository(),
    ),
    achievementRepositoryProvider.overrideWithValue(
      FakeAchievementRepository(),
    ),
    rankingRepositoryProvider.overrideWithValue(
      ranking ?? FakeRankingRepository(),
    ),
    profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
  ];
}

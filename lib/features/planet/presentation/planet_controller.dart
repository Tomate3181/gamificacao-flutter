import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/game_failure.dart';
import '../../achievements/domain/achievement.dart';
import '../../auth/presentation/session_providers.dart';
import '../../missions/presentation/progress_sync.dart';
import '../../player/domain/economy.dart';
import '../../player/presentation/player_controller.dart';
import '../../shop/domain/upgrade.dart';
import '../../shop/presentation/shop_controller.dart';
import '../data/planet_repository.dart';
import '../domain/planet_models.dart';
import 'lumi_controller.dart';

final planetControllerProvider =
    AsyncNotifierProvider<PlanetController, PlanetState>(PlanetController.new);

/// Região sendo plantada agora (mostra carregamento no lugar).
final plantingSlotProvider = NotifierProvider<PlantingSlot, int?>(
  PlantingSlot.new,
);

class PlantingSlot extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? slot) => state = slot;
}

/// Custo em energia de cada espécie no planeta atual, já com desconto.
final speciesCostProvider = Provider.family<double, TreeSpecies>((
  ref,
  species,
) {
  final planet = ref.watch(planetControllerProvider).value?.planet;
  final costBonus = ref.watch(upgradeBonusProvider(UpgradeCategory.cost));
  return Economy.treeCost(
    speciesCost: species.cost,
    planetBaseCost: planet?.baseCost ?? 10,
    costBonus: costBonus,
  );
});

/// Tempo de crescimento de cada espécie, já com o bônus de Crescimento.
final speciesGrowTimeProvider = Provider.family<Duration, TreeSpecies>((
  ref,
  species,
) {
  final growthBonus = ref.watch(upgradeBonusProvider(UpgradeCategory.growth));
  return Economy.growTime(species.growSeconds, growthBonus: growthBonus);
});

typedef PlantOutcome = ({
  GameFailure? failure,
  PlanetCompletion? completion,
  List<UnlockedAchievement> achievements,
});

const PlantOutcome _nothing = (
  failure: null,
  completion: null,
  achievements: <UnlockedAchievement>[],
);

class PlanetController extends AsyncNotifier<PlanetState> {
  @override
  Future<PlanetState> build() async {
    final userId = await requireUserId(ref);
    return ref.read(planetRepositoryProvider).fetchCurrent(userId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Depois de concluir o planeta: carrega o próximo sem tirar o atual da
  /// tela enquanto busca (a troca é animada na página).
  Future<void> travelToNext() async {
    final userId = await requireUserId(ref);
    final next = await AsyncValue.guard(
      () => ref.read(planetRepositoryProvider).fetchCurrent(userId),
    );
    if (!ref.mounted) return;
    state = next;
    ref.read(lumiControllerProvider.notifier).celebrate();
  }

  Future<PlantOutcome> plant({
    required int slotIndex,
    required int speciesId,
  }) async {
    final planting = ref.read(plantingSlotProvider.notifier);
    if (ref.read(plantingSlotProvider) != null) return _nothing;
    planting.set(slotIndex);
    ref.read(lumiControllerProvider.notifier).follow(slotIndex);

    try {
      final result = await ref
          .read(planetRepositoryProvider)
          .plantTree(slotIndex: slotIndex, speciesId: speciesId);
      if (!ref.mounted) return _nothing;

      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.withPlantedTree(
            result.tree,
            reforestedSlots: result.reforestedSlots,
            isCompleted: result.planetCompleted,
          ),
        );
      }
      ref
          .read(playerControllerProvider.notifier)
          .applyServerValues(
            energy: result.energy,
            totalPoints: result.totalPoints,
          );
      if (result.planetCompleted || result.achievements.isNotEmpty) {
        ref.read(lumiControllerProvider.notifier).celebrate();
      }
      syncGameProgress(ref, achievements: true);
      return (
        failure: null,
        completion: result.planetCompleted
            ? PlanetCompletion(
                planetName: current?.planet.name ?? 'Planeta',
                pointsEarned: result.pointsEarned,
                next: result.nextPlanet,
              )
            : null,
        achievements: result.achievements,
      );
    } on GameFailure catch (failure) {
      ref.read(lumiControllerProvider.notifier).wander();
      return (
        failure: failure,
        completion: null,
        achievements: const <UnlockedAchievement>[],
      );
    } finally {
      if (ref.mounted) planting.set(null);
    }
  }
}

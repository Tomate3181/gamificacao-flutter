import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/game_failure.dart';
import '../../auth/presentation/session_providers.dart';
import '../../planet/presentation/lumi_controller.dart';
import '../../player/presentation/player_controller.dart';
import '../data/mission_repository.dart';
import '../domain/mission.dart';
import 'progress_sync.dart';

final missionsControllerProvider =
    AsyncNotifierProvider<MissionsController, List<MissionView>>(
      MissionsController.new,
    );

/// Missão com ação em andamento (iniciar ou resgatar).
final missionActionProvider = NotifierProvider<MissionAction, int?>(
  MissionAction.new,
);

class MissionAction extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? missionId) => state = missionId;
}

/// Missão em destaque na home: a primeira não concluída da lista ordenada.
final featuredMissionProvider = Provider<MissionView?>((ref) {
  final missions = ref.watch(missionsControllerProvider).value ?? const [];
  return missions.where((m) => m.status != MissionStatus.completed).firstOrNull;
});

final missionByIdProvider = Provider.family<AsyncValue<MissionView?>, int>((
  ref,
  id,
) {
  return ref
      .watch(missionsControllerProvider)
      .whenData((missions) => missions.where((m) => m.id == id).firstOrNull);
});

typedef ClaimOutcome = ({GameFailure? failure, MissionClaim? claim});

class MissionsController extends AsyncNotifier<List<MissionView>> {
  @override
  Future<List<MissionView>> build() async {
    final userId = await requireUserId(ref);
    final missions = await ref
        .read(missionRepositoryProvider)
        .fetchMissions(userId);
    return sortMissions(missions);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Atualiza o progresso sem mostrar carregamento (erros são ignorados:
  /// a próxima atualização tenta de novo).
  Future<void> refreshSilently() async {
    if (!state.hasValue) return;
    try {
      final userId = await readUserId(ref);
      final missions = await ref
          .read(missionRepositoryProvider)
          .fetchMissions(userId);
      if (ref.mounted) state = AsyncData(sortMissions(missions));
    } catch (_) {}
  }

  Future<GameFailure?> start(int missionId) async {
    if (!_begin(missionId)) return null;
    try {
      final progress = await ref
          .read(missionRepositoryProvider)
          .start(missionId);
      if (ref.mounted) {
        _update(
          missionId,
          (m) => m.copyWith(started: true, progress: progress),
        );
      }
      return null;
    } on GameFailure catch (failure) {
      return failure;
    } finally {
      _end();
    }
  }

  Future<ClaimOutcome> claim(int missionId) async {
    if (!_begin(missionId)) return (failure: null, claim: null);
    try {
      final claim = await ref.read(missionRepositoryProvider).claim(missionId);
      if (!ref.mounted) return (failure: null, claim: claim);

      _update(missionId, (m) => m.copyWith(completed: true));
      ref
          .read(playerControllerProvider.notifier)
          .applyServerValues(
            energy: claim.energy,
            totalPoints: claim.totalPoints,
          );
      ref.read(lumiControllerProvider.notifier).celebrate();
      syncAfterReward(ref);
      return (failure: null, claim: claim);
    } on GameFailure catch (failure) {
      // O progresso pode ter mudado no servidor: atualiza a lista.
      refreshSilently();
      return (failure: failure, claim: null);
    } finally {
      _end();
    }
  }

  bool _begin(int missionId) {
    if (ref.read(missionActionProvider) != null) return false;
    ref.read(missionActionProvider.notifier).set(missionId);
    return true;
  }

  void _end() {
    if (ref.mounted) ref.read(missionActionProvider.notifier).set(null);
  }

  void _update(int missionId, MissionView Function(MissionView) change) {
    final missions = state.value ?? const <MissionView>[];
    state = AsyncData(
      sortMissions([
        for (final mission in missions)
          mission.id == missionId ? change(mission) : mission,
      ]),
    );
  }
}

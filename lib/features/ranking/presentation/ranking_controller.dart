import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_providers.dart';
import '../data/ranking_repository.dart';
import '../domain/ranking_entry.dart';

final rankingControllerProvider =
    AsyncNotifierProvider<RankingController, RankingBoard>(
      RankingController.new,
    );

class RankingController extends AsyncNotifier<RankingBoard> {
  @override
  Future<RankingBoard> build() async {
    // Recarrega quando outra pessoa entra na conta.
    await requireUserId(ref);
    return ref.read(rankingRepositoryProvider).fetchRanking();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Atualiza mantendo a lista atual na tela (puxar para atualizar).
  Future<void> refresh() async {
    try {
      final board = await ref.read(rankingRepositoryProvider).fetchRanking();
      if (ref.mounted) state = AsyncData(board);
    } catch (error, stackTrace) {
      if (ref.mounted && !state.hasValue) {
        state = AsyncError(error, stackTrace);
      }
    }
  }
}

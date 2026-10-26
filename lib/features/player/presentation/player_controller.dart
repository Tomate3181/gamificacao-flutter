import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_providers.dart';
import '../data/player_repository.dart';
import '../domain/player_stats.dart';

/// Energia, oxigênio e pontos do jogador.
///
/// Os valores só mudam com o que o servidor devolve nas RPCs; as outras
/// features chamam [applyServerValues] com esses números.
final playerControllerProvider =
    AsyncNotifierProvider<PlayerController, PlayerStats>(PlayerController.new);

class PlayerController extends AsyncNotifier<PlayerStats> {
  @override
  Future<PlayerStats> build() async {
    final userId = await requireUserId(ref);
    return ref.read(playerRepositoryProvider).fetchStats(userId);
  }

  void applyServerValues({double? energy, double? oxygen, int? totalPoints}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        energy: energy,
        oxygen: oxygen,
        totalPoints: totalPoints,
      ),
    );
  }

  /// Coleta o oxigênio produzido. Retorna quanto foi coletado (0 se falhar,
  /// porque a próxima coleta recupera o período).
  Future<double> collectOxygen() async {
    if (state.value == null) return 0;
    try {
      final result = await ref.read(playerRepositoryProvider).collectOxygen();
      if (!ref.mounted) return 0;
      applyServerValues(oxygen: result.oxygen);
      return result.collected;
    } catch (_) {
      return 0;
    }
  }
}

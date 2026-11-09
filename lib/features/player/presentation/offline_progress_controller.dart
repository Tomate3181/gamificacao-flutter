import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../missions/presentation/progress_sync.dart';
import '../data/player_repository.dart';
import '../domain/offline_report.dart';
import 'player_controller.dart';

/// Relatório do tempo fora do app esperando para ser mostrado
/// (`null` = nada a mostrar).
final offlineProgressControllerProvider =
    NotifierProvider<OfflineProgressController, OfflineReport?>(
      OfflineProgressController.new,
    );

class OfflineProgressController extends Notifier<OfflineReport?> {
  bool _collecting = false;

  @override
  OfflineReport? build() => null;

  /// Coleta o oxigênio do tempo fora. Chamado ao abrir o app e ao voltar
  /// para ele. Falhas são ignoradas: a próxima coleta recupera o período.
  Future<void> collect() async {
    if (_collecting) return;
    _collecting = true;
    try {
      // Espera o perfil carregar para aplicar o novo total de oxigênio.
      await ref.read(playerControllerProvider.future);
      if (!ref.mounted) return;
      final report = await ref
          .read(playerRepositoryProvider)
          .collectOfflineOxygen();
      if (!ref.mounted) return;
      ref
          .read(playerControllerProvider.notifier)
          .applyServerValues(oxygen: report.oxygen);
      if (report.oxygenGained > 0) syncGameProgress(ref);
      if (report.isWorthShowing) state = report;
    } catch (_) {
      // Sem conexão: tenta de novo na próxima volta ao app.
    } finally {
      _collecting = false;
    }
  }

  void dismiss() => state = null;
}

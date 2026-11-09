import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../achievements/presentation/achievements_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../ranking/presentation/ranking_controller.dart';
import 'missions_controller.dart';

/// Depois de uma ação do jogo (passos, plantio, oxigênio, upgrade), o
/// servidor pode ter avançado missões e conquistas. Atualiza em silêncio
/// só as telas que já foram abertas.
void syncGameProgress(
  Ref ref, {
  bool achievements = false,
  bool missions = true,
}) {
  if (missions && ref.exists(missionsControllerProvider)) {
    ref.read(missionsControllerProvider.notifier).refreshSilently();
  }
  if (achievements && ref.exists(achievementsControllerProvider)) {
    ref.read(achievementsControllerProvider.notifier).refreshSilently();
  }
  if (ref.exists(profileControllerProvider)) {
    ref.read(profileControllerProvider.notifier).refreshSilently();
  }
}

/// Depois de resgatar uma missão: atualiza conquistas, perfil e ranking.
/// A lista de missões já foi atualizada por quem chamou.
void syncAfterReward(Ref ref) {
  syncGameProgress(ref, achievements: true, missions: false);
  if (ref.exists(rankingControllerProvider)) {
    ref.read(rankingControllerProvider.notifier).refresh();
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/sprites.dart';
import '../../../core/utils/number_format.dart';
import '../../../widgets/mission_card.dart';
import '../domain/mission.dart';

/// "150 de 200 passos".
String missionProgressLabel(MissionView mission) {
  final done = mission.completed ? mission.goalValue : mission.progress.floor();
  return '${formatResource(done.toDouble())} de '
      '${formatResource(mission.goalValue.toDouble())} ${mission.category.unit}';
}

/// [MissionCard] preenchido com uma missão; abre os detalhes ao tocar.
class MissionTile extends StatelessWidget {
  const MissionTile({super.key, required this.mission});

  final MissionView mission;

  @override
  Widget build(BuildContext context) {
    final status = mission.status;
    final showProgress = status != MissionStatus.available;

    return MissionCard(
      title: mission.title,
      description: mission.description,
      iconAsset: Sprites.missionCategory(mission.category.name),
      categoryLabel: mission.category.label,
      difficultyLabel: mission.difficulty.label,
      statusLabel: status.label,
      points: mission.points,
      energy: mission.energyReward,
      progress: showProgress ? mission.progressRatio : null,
      progressLabel: showProgress ? missionProgressLabel(mission) : null,
      isReady: status == MissionStatus.readyToClaim,
      isCompleted: status == MissionStatus.completed,
      onTap: () => context.go(AppRoutes.missionDetails(mission.id)),
    );
  }
}

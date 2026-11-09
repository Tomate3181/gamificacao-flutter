import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sprites.dart';
import '../../../widgets/eco_button.dart';
import '../../../widgets/error_retry.dart';
import '../../../widgets/pixel_image.dart';
import '../../../widgets/reward_burst.dart';
import '../domain/mission.dart';
import 'mission_tile.dart';
import 'missions_controller.dart';

/// Detalhes da missão (`/missions/:id`).
class MissionDetailsPage extends ConsumerWidget {
  const MissionDetailsPage({super.key, required this.missionId});

  final int missionId;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(missionsControllerProvider.notifier)
        .start(missionId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure?.message ??
                'Missão iniciada! O progresso já está contando.',
          ),
        ),
      );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref
        .read(missionsControllerProvider.notifier)
        .claim(missionId);
    final claim = outcome.claim;
    final lines = [
      if (outcome.failure != null) outcome.failure!.message,
      if (claim != null)
        'Recompensa resgatada: +${claim.pointsEarned} pontos e '
            '+${claim.energyEarned} de energia!',
      for (final achievement in claim?.achievements ?? const [])
        'Conquista desbloqueada: ${achievement.name}!',
    ];
    if (lines.isEmpty) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(lines.join('\n'))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionByIdProvider(missionId));
    final busy = ref.watch(missionActionProvider) == missionId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missão'),
        leading: IconButton(
          tooltip: 'Voltar para missões',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.missions),
        ),
      ),
      body: missionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorRetry(
          message: 'Não foi possível carregar a missão.',
          onRetry: () => ref.read(missionsControllerProvider.notifier).reload(),
        ),
        data: (mission) {
          if (mission == null) {
            return ErrorRetry(
              message: 'Missão não encontrada.',
              onRetry: () => context.go(AppRoutes.missions),
            );
          }
          return _Details(
            mission: mission,
            busy: busy,
            onStart: () => _start(context, ref),
            onClaim: () => _claim(context, ref),
          );
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.mission,
    required this.busy,
    required this.onStart,
    required this.onClaim,
  });

  final MissionView mission;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = mission.status;
    final isReady = status == MissionStatus.readyToClaim;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                // Ao resgatar, a missão vira "concluída" e solta partículas.
                child: RewardBurst(
                  trigger: mission.status == MissionStatus.completed
                      ? mission.id
                      : null,
                  particles: const [
                    Sprites.points,
                    Sprites.energy,
                    Sprites.leaf,
                  ],
                  count: 14,
                  distance: 80,
                  particleSize: 18,
                  duration: const Duration(milliseconds: 1200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.skyMid,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isReady ? AppColors.gold : AppColors.outline,
                        width: 2,
                      ),
                    ),
                    child: PixelImage(
                      Sprites.missionCategory(mission.category.name),
                      size: 72,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                mission.title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${mission.category.label} · ${mission.difficulty.label} · '
                '${status.label}',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'Objetivo',
                child: Text(mission.description, style: textTheme.bodyLarge),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Dica',
                child: Text(mission.guidance, style: textTheme.bodyMedium),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Recompensa',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const PixelImage(Sprites.points, size: 24),
                    Text(
                      '+${mission.points} pontos',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(width: 14),
                    const PixelImage(Sprites.energy, size: 24),
                    Text(
                      '+${mission.energyReward} de energia',
                      style: textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              if (status != MissionStatus.available) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Progresso',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: mission.progressRatio,
                          minHeight: 10,
                          backgroundColor: AppColors.skyDeep,
                          color: isReady || mission.completed
                              ? AppColors.gold
                              : AppColors.auroraTeal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        missionProgressLabel(mission),
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              switch (status) {
                MissionStatus.available => EcoButton(
                  label: 'Iniciar missão',
                  icon: Icons.play_arrow,
                  isLoading: busy,
                  onPressed: onStart,
                ),
                MissionStatus.inProgress => const FilledButton(
                  onPressed: null,
                  child: Text('Em andamento: continue jogando'),
                ),
                MissionStatus.readyToClaim => EcoButton(
                  label: 'Resgatar recompensa',
                  icon: Icons.redeem,
                  isLoading: busy,
                  onPressed: onClaim,
                ),
                MissionStatus.completed => const FilledButton(
                  onPressed: null,
                  child: Text('Missão concluída'),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.skyMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

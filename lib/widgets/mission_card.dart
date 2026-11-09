import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/sprites.dart';
import 'pixel_image.dart';

/// Cartão de missão: ícone, título, progresso e recompensa.
class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.categoryLabel,
    required this.difficultyLabel,
    required this.statusLabel,
    required this.points,
    required this.energy,
    required this.onTap,
    this.progress,
    this.progressLabel,
    this.isReady = false,
    this.isCompleted = false,
  });

  final String title;
  final String description;
  final String iconAsset;
  final String categoryLabel;
  final String difficultyLabel;
  final String statusLabel;
  final int points;
  final int energy;
  final VoidCallback onTap;

  /// Progresso de 0 a 1 (null esconde a barra).
  final double? progress;

  /// Ex.: "150 de 200 passos".
  final String? progressLabel;

  /// Chegou na meta: destaque dourado.
  final bool isReady;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = isReady ? AppColors.gold : AppColors.outline;
    final progress = this.progress;

    return Semantics(
      button: true,
      label: '$title. $statusLabel.',
      child: Opacity(
        opacity: isCompleted ? 0.7 : 1,
        child: Material(
          color: AppColors.skyMid,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: isReady ? 2 : 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.skyDeep,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PixelImage(iconAsset, size: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusChip(
                          label: statusLabel,
                          isReady: isReady,
                          isCompleted: isCompleted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (progress != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.skyDeep,
                              color: isReady
                                  ? AppColors.gold
                                  : AppColors.auroraTeal,
                            ),
                          ),
                          if (progressLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              progressLabel!,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _Reward(asset: Sprites.points, value: '+$points'),
                            _Reward(asset: Sprites.energy, value: '+$energy'),
                            Text(
                              '$categoryLabel · $difficultyLabel',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isReady,
    required this.isCompleted,
  });

  final String label;
  final bool isReady;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final color = isReady
        ? AppColors.gold
        : isCompleted
        ? AppColors.leafGreen
        : AppColors.auroraLilac;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward({required this.asset, required this.value});

  final String asset;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelImage(asset, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

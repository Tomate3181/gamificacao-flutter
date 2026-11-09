import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'pixel_image.dart';

/// Conquista desbloqueada (colorida) ou bloqueada (cinza, com a condição).
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.isUnlocked,
  });

  final String name;

  /// Condição para desbloquear.
  final String description;
  final String iconAsset;
  final bool isUnlocked;

  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 0.5, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = PixelImage(iconAsset, size: 56);

    return Semantics(
      label:
          '$name, ${isUnlocked ? 'desbloqueada' : 'bloqueada'}. $description',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.skyMid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked ? AppColors.gold : AppColors.outline,
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (isUnlocked)
                  icon
                else
                  ColorFiltered(colorFilter: _grayscale, child: icon),
                if (!isUnlocked)
                  const Positioned(
                    right: -6,
                    bottom: -6,
                    child: Icon(
                      Icons.lock,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Barra de progresso do planeta, no topo da tela.
class PlanetProgressBar extends StatelessWidget {
  const PlanetProgressBar({
    super.key,
    required this.planetName,
    required this.reforested,
    required this.total,
  });

  final String planetName;
  final int reforested;
  final int total;

  double get progress => total == 0 ? 0 : (reforested / total).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percent = (progress * 100).floor();

    return Semantics(
      label: '$planetName: $percent% reflorestado',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  planetName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percent%',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.leafGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: AppColors.skyMid,
                color: AppColors.leafGreen,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$reforested de $total regiões reflorestadas',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

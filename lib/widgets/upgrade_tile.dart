import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Item da loja: nome, descrição, nível e botão de compra.
class UpgradeTile extends StatelessWidget {
  const UpgradeTile({
    super.key,
    required this.icon,
    required this.name,
    required this.description,
    required this.level,
    required this.maxLevel,
    required this.bonusLabel,
    required this.costLabel,
    required this.canAfford,
    required this.onBuy,
    this.isLoading = false,
  });

  final IconData icon;
  final String name;
  final String description;
  final int level;
  final int maxLevel;

  /// Ex.: "-15% no custo de plantio".
  final String bonusLabel;

  /// Ex.: "75 O₂".
  final String costLabel;
  final bool canAfford;
  final VoidCallback onBuy;
  final bool isLoading;

  bool get isMaxed => level >= maxLevel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.skyMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.auroraTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.auroraTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Nível $level de $maxLevel',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            bonusLabel,
            style: textTheme.bodySmall?.copyWith(color: AppColors.leafGreen),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maxLevel == 0 ? 0 : level / maxLevel,
              minHeight: 6,
              backgroundColor: AppColors.skyDeep,
              color: AppColors.auroraLilac,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: isMaxed || !canAfford || isLoading ? null : onBuy,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.skyDeep,
                      ),
                    )
                  : Text(
                      isMaxed
                          ? 'Nível máximo'
                          : canAfford
                          ? 'Melhorar por $costLabel'
                          : 'Oxigênio insuficiente · $costLabel',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

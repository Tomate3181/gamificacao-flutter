import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../widgets/tree_sprite.dart';
import '../domain/planet_models.dart';
import 'planet_controller.dart';

/// Abre a lista de espécies e devolve o id escolhido (ou `null`).
Future<int?> showSpeciesPicker(
  BuildContext context, {
  required List<TreeSpecies> species,
  required double energy,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (context) => _SpeciesPicker(species: species, energy: energy),
  );
}

class _SpeciesPicker extends ConsumerWidget {
  const _SpeciesPicker({required this.species, required this.energy});

  final List<TreeSpecies> species;
  final double energy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O que plantar aqui?',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Você tem ${formatResource(energy)} de energia.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: species.isEmpty
                ? const Center(child: Text('Nenhuma espécie disponível.'))
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: species.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = species[index];
                      final cost = ref.watch(speciesCostProvider(item));
                      final canAfford = energy >= cost;
                      return _SpeciesTile(
                        species: item,
                        cost: cost,
                        canAfford: canAfford,
                        onTap: () => context.pop(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesTile extends StatelessWidget {
  const _SpeciesTile({
    required this.species,
    required this.cost,
    required this.canAfford,
    required this.onTap,
  });

  final TreeSpecies species;
  final double cost;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.textMuted);

    return Opacity(
      opacity: canAfford ? 1 : 0.55,
      child: Material(
        color: AppColors.skyMid,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canAfford ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                TreeSprite(speciesId: species.id, growth: 1, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        species.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${formatResource(species.oxygenPerSec)} O₂/s · '
                        'cresce em ${_formatDuration(species.growSeconds)}',
                        style: muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatResource(cost),
                      style: textTheme.titleMedium?.copyWith(
                        color: canAfford ? AppColors.gold : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(canAfford ? 'energia' : 'falta energia', style: muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return rest == 0 ? '${minutes}min' : '${minutes}min ${rest}s';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sprites.dart';
import '../../../core/utils/number_format.dart';
import '../../../widgets/error_retry.dart';
import '../../../widgets/lumi_sprite.dart';
import '../../../widgets/resource_counter.dart';
import '../../../widgets/upgrade_tile.dart';
import '../../../widgets/upgrade_tree_view.dart';
import '../../player/presentation/player_controller.dart';
import '../domain/upgrade.dart';
import 'shop_controller.dart';
import 'upgrade_labels.dart';

/// Loja: árvore radial de upgrades. Tocar num nó mostra o cartão dele
/// embaixo, com o botão de compra.
class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  Future<void> _buy(BuildContext context, WidgetRef ref, ShopItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(shopControllerProvider.notifier)
        .buy(item.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure?.message ??
                '${item.name} subiu para o nível ${item.level + 1}!',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shopControllerProvider);
    final tree = ref.watch(upgradeTreeProvider);
    final oxygen = ref.watch(playerControllerProvider).value?.oxygen;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loja',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              tree == null
                                  ? 'Árvore de melhorias'
                                  : '${tree.ownedLevels} de ${tree.totalLevels} níveis',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ResourceCounter(
                        iconAsset: Sprites.oxygen,
                        label: 'Oxigênio',
                        value: oxygen == null ? '…' : formatResource(oxygen),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: itemsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: ErrorRetry(
                        message:
                            'Não foi possível carregar a loja. '
                            'Verifique sua conexão e tente de novo.',
                        onRetry: () => ref.invalidate(shopControllerProvider),
                      ),
                    ),
                    data: (items) => items.isEmpty || tree == null
                        ? const Center(
                            child: Text(
                              'Nenhum upgrade disponível no momento.',
                            ),
                          )
                        : _TreeContent(
                            tree: tree,
                            oxygen: oxygen ?? 0,
                            onBuy: (item) => _buy(context, ref, item),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TreeContent extends ConsumerWidget {
  const _TreeContent({
    required this.tree,
    required this.oxygen,
    required this.onBuy,
  });

  final UpgradeTree tree;
  final double oxygen;
  final ValueChanged<ShopItem> onBuy;

  static UpgradeTreeNodeState _state(UpgradeNodeStatus status) =>
      switch (status) {
        UpgradeNodeStatus.locked => UpgradeTreeNodeState.locked,
        UpgradeNodeStatus.available => UpgradeTreeNodeState.available,
        UpgradeNodeStatus.owned => UpgradeTreeNodeState.owned,
        UpgradeNodeStatus.maxed => UpgradeTreeNodeState.maxed,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedUpgradeIdProvider);
    final buyingId = ref.watch(buyingUpgradeIdProvider);
    final selected =
        (selectedId == null ? null : tree.byId(selectedId)) ?? tree.suggested();

    final nodes = [
      for (final item in tree.items)
        UpgradeTreeNode(
          id: item.id,
          parentId: item.parentId,
          tier: item.tier,
          angle: nodeAngle(item),
          icon: categoryIcon(item.category),
          color: item.branch.color,
          level: item.level,
          maxLevel: item.maxLevel,
          state: _state(tree.statusOf(item)),
          semanticLabel:
              '${item.name}, ramo ${item.branch.label}, '
              'nível ${item.level} de ${item.maxLevel}'
              '${tree.isUnlocked(item) ? '' : ', bloqueado'}',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Espaço da árvore: o que sobra depois do cartão e da barra
        // flutuante, sem ficar pequeno demais em telas baixas.
        final treeHeight = (constraints.maxHeight - 330).clamp(260.0, 620.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: treeHeight,
                decoration: BoxDecoration(
                  color: AppColors.skyDeep,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.auroraLilac.withValues(alpha: 0.10),
                      AppColors.skyDeep,
                    ],
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: UpgradeTreeView(
                  nodes: nodes,
                  selectedId: selected?.id,
                  center: const LumiSprite(mood: LumiMood.wandering, size: 52),
                  onNodeTap: (id) =>
                      ref.read(selectedUpgradeIdProvider.notifier).select(id),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final branch in UpgradeBranch.values)
                    _Legend(color: branch.color, label: branch.label),
                ],
              ),
              const SizedBox(height: 12),
              if (selected != null)
                UpgradeTile(
                  icon: categoryIcon(selected.category),
                  accentColor: selected.branch.color,
                  name: selected.name,
                  subtitle: 'Ramo ${selected.branch.label}',
                  description: selected.description,
                  level: selected.level,
                  maxLevel: selected.maxLevel,
                  bonusLabel: bonusLabel(selected),
                  costLabel: '${formatResource(selected.nextCost)} O₂',
                  canAfford: oxygen >= selected.nextCost,
                  isLoading: buyingId == selected.id,
                  lockedLabel: tree.isUnlocked(selected)
                      ? null
                      : 'Compre ${tree.parentOf(selected)?.name} antes',
                  onBuy: () => onBuy(selected),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

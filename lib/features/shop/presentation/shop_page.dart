import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../widgets/eco_button.dart';
import '../../../widgets/message_banner.dart';
import '../../../widgets/resource_counter.dart';
import '../../../widgets/upgrade_tile.dart';
import '../../player/presentation/player_controller.dart';
import '../domain/upgrade.dart';
import 'shop_controller.dart';

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
    final oxygen = ref.watch(playerControllerProvider).value?.oxygen;
    final buyingId = ref.watch(buyingUpgradeIdProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Loja',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upgrades são permanentes e valem em todos os planetas.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ResourceCounter(
                            icon: Icons.air,
                            label: 'Oxigênio disponível',
                            value: oxygen == null
                                ? '…'
                                : formatResource(oxygen),
                            color: AppColors.auroraTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...itemsAsync.when(
                  loading: () => const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (_, _) => [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const MessageBanner(
                              message:
                                  'Não foi possível carregar a loja. '
                                  'Verifique sua conexão e tente de novo.',
                            ),
                            const SizedBox(height: 16),
                            EcoButton(
                              label: 'Tentar de novo',
                              icon: Icons.refresh,
                              onPressed: () =>
                                  ref.invalidate(shopControllerProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  data: (items) => [
                    if (items.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('Nenhum upgrade disponível no momento.'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        sliver: SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return UpgradeTile(
                              icon: _iconFor(item.category),
                              name: item.name,
                              description: item.description,
                              level: item.level,
                              maxLevel: item.maxLevel,
                              bonusLabel: _bonusLabel(item),
                              costLabel: '${formatResource(item.nextCost)} O₂',
                              canAfford: (oxygen ?? 0) >= item.nextCost,
                              isLoading: buyingId == item.id,
                              onBuy: () => _buy(context, ref, item),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(UpgradeCategory category) => switch (category) {
    UpgradeCategory.cost => Icons.savings_outlined,
    UpgradeCategory.production => Icons.air,
    UpgradeCategory.energy => Icons.directions_walk,
    UpgradeCategory.growth => Icons.spa_outlined,
    UpgradeCategory.automation => Icons.precision_manufacturing_outlined,
  };

  static String _bonusLabel(ShopItem item) {
    final percent = (item.bonus * 100).round();
    if (item.level == 0) return 'Ainda sem bônus';
    return switch (item.category) {
      UpgradeCategory.cost => '-$percent% no custo de plantio',
      UpgradeCategory.production => '+$percent% de oxigênio',
      UpgradeCategory.energy => '+$percent% de energia por passo',
      UpgradeCategory.growth => '-$percent% no tempo de crescimento',
      UpgradeCategory.automation => '${item.level} drone(s)',
    };
  }
}

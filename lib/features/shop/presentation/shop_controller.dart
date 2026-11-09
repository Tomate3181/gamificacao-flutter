import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/game_failure.dart';
import '../../auth/presentation/session_providers.dart';
import '../../missions/presentation/progress_sync.dart';
import '../../player/presentation/player_controller.dart';
import '../data/shop_repository.dart';
import '../domain/upgrade.dart';

final shopControllerProvider =
    AsyncNotifierProvider<ShopController, List<ShopItem>>(ShopController.new);

/// Id do upgrade sendo comprado agora (para o botão mostrar carregamento).
final buyingUpgradeIdProvider = NotifierProvider<BuyingUpgrade, int?>(
  BuyingUpgrade.new,
);

class BuyingUpgrade extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? upgradeId) => state = upgradeId;
}

/// Nó escolhido na árvore (null = o sugerido).
final selectedUpgradeIdProvider = NotifierProvider<SelectedUpgrade, int?>(
  SelectedUpgrade.new,
);

class SelectedUpgrade extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? upgradeId) => state = upgradeId;
}

/// Árvore de upgrades montada a partir da loja (null enquanto carrega).
final upgradeTreeProvider = Provider<UpgradeTree?>((ref) {
  final items = ref.watch(shopControllerProvider).value;
  return items == null ? null : UpgradeTree(items);
});

/// Bônus atual por categoria. Vale 0 enquanto a loja carrega.
final upgradeBonusProvider = Provider.family<double, UpgradeCategory>((
  ref,
  category,
) {
  return ref.watch(upgradeTreeProvider)?.bonus(category) ?? 0;
});

class ShopController extends AsyncNotifier<List<ShopItem>> {
  @override
  Future<List<ShopItem>> build() async {
    final userId = await requireUserId(ref);
    return ref.read(shopRepositoryProvider).fetchItems(userId);
  }

  /// Compra o próximo nível. Retorna o erro, ou `null` se deu certo.
  Future<GameFailure?> buy(int upgradeId) async {
    final buying = ref.read(buyingUpgradeIdProvider.notifier);
    if (ref.read(buyingUpgradeIdProvider) != null) return null;
    buying.set(upgradeId);
    try {
      final result = await ref.read(shopRepositoryProvider).buy(upgradeId);
      if (!ref.mounted) return null;
      final items = state.value ?? const [];
      state = AsyncData([
        for (final item in items)
          item.id == upgradeId ? item.withLevel(result.level) : item,
      ]);
      ref
          .read(playerControllerProvider.notifier)
          .applyServerValues(oxygen: result.oxygen);
      syncGameProgress(ref);
      return null;
    } on GameFailure catch (failure) {
      return failure;
    } finally {
      if (ref.mounted) buying.set(null);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/game_failure.dart';
import '../../auth/presentation/session_providers.dart';
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

/// Bônus atual por categoria. Vale 0 enquanto a loja carrega.
final upgradeBonusProvider = Provider.family<double, UpgradeCategory>((
  ref,
  category,
) {
  final items = ref.watch(shopControllerProvider).value ?? const [];
  return items
      .where((item) => item.category == category)
      .fold(0.0, (sum, item) => sum + item.bonus);
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
      return null;
    } on GameFailure catch (failure) {
      return failure;
    } finally {
      if (ref.mounted) buying.set(null);
    }
  }
}

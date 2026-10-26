import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_guard.dart';
import '../domain/upgrade.dart';

final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => SupabaseShopRepository(ref.watch(supabaseClientProvider)),
);

abstract interface class ShopRepository {
  /// Upgrades liberados na loja, com o nível do jogador.
  Future<List<ShopItem>> fetchItems(String userId);

  /// Compra o próximo nível. Retorna (novo nível, oxigênio restante).
  Future<({int level, double oxygen})> buy(int upgradeId);
}

class SupabaseShopRepository implements ShopRepository {
  SupabaseShopRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ShopItem>> fetchItems(String userId) {
    return guardSupabase(() async {
      final upgrades = await _client
          .from('upgrades')
          .select()
          .eq('is_available', true)
          .order('id');
      final owned = await _client
          .from('user_upgrades')
          .select('upgrade_id, level')
          .eq('user_id', userId);

      final levels = {
        for (final row in owned)
          (row['upgrade_id'] as num).toInt(): (row['level'] as num).toInt(),
      };

      return [
        for (final row in upgrades)
          ShopItem(
            id: (row['id'] as num).toInt(),
            category: UpgradeCategory.fromName(row['category'] as String),
            name: row['name'] as String,
            description: row['description'] as String,
            maxLevel: (row['max_level'] as num).toInt(),
            baseCost: readNum(row['base_cost']),
            costMultiplier: readNum(row['cost_multiplier']),
            effect: readNum(row['effect']),
            level: levels[(row['id'] as num).toInt()] ?? 0,
          ),
      ];
    });
  }

  @override
  Future<({int level, double oxygen})> buy(int upgradeId) {
    return guardSupabase(() async {
      final result =
          await _client.rpc('buy_upgrade', params: {'p_upgrade_id': upgradeId})
              as Map<String, dynamic>;
      return (
        level: (result['level'] as num).toInt(),
        oxygen: readNum(result['oxygen']),
      );
    });
  }
}

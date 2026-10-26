import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_guard.dart';
import '../domain/player_stats.dart';

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => SupabasePlayerRepository(ref.watch(supabaseClientProvider)),
);

abstract interface class PlayerRepository {
  Future<PlayerStats> fetchStats(String userId);

  /// Coleta o oxigênio das árvores prontas. Retorna (coletado, total).
  Future<({double collected, double oxygen})> collectOxygen();
}

class SupabasePlayerRepository implements PlayerRepository {
  SupabasePlayerRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PlayerStats> fetchStats(String userId) {
    return guardSupabase(() async {
      final row = await _client
          .from('profiles')
          .select('nickname, energy, oxygen, total_points')
          .eq('id', userId)
          .single();
      return PlayerStats(
        nickname: row['nickname'] as String,
        energy: readNum(row['energy']),
        oxygen: readNum(row['oxygen']),
        totalPoints: (row['total_points'] as num).toInt(),
      );
    });
  }

  @override
  Future<({double collected, double oxygen})> collectOxygen() {
    return guardSupabase(() async {
      final result =
          await _client.rpc('collect_oxygen') as Map<String, dynamic>;
      return (
        collected: readNum(result['oxygen_collected']),
        oxygen: readNum(result['oxygen']),
      );
    });
  }
}

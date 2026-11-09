import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_guard.dart';
import '../domain/profile_summary.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

abstract interface class ProfileRepository {
  Future<ProfileSummary> fetchSummary(String userId);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ProfileSummary> fetchSummary(String userId) {
    return guardSupabase(() async {
      // O RLS já limita cada consulta às linhas do próprio jogador.
      final results = await Future.wait([
        _client
            .from('user_missions')
            .select('mission_id')
            .eq('user_id', userId)
            .eq('status', 'completed')
            .count(CountOption.exact),
        _client
            .from('user_achievements')
            .select('achievement_id')
            .eq('user_id', userId)
            .count(CountOption.exact),
        _client.from('achievements').select('id').count(CountOption.exact),
        _client
            .from('user_planets')
            .select('id')
            .eq('user_id', userId)
            .not('completed_at', 'is', null)
            .count(CountOption.exact),
        _client
            .from('user_trees')
            .select('id')
            .eq('user_id', userId)
            .count(CountOption.exact),
      ]);

      return ProfileSummary(
        missionsCompleted: results[0].count,
        achievementsUnlocked: results[1].count,
        achievementsTotal: results[2].count,
        planetsCompleted: results[3].count,
        treesPlanted: results[4].count,
      );
    });
  }
}

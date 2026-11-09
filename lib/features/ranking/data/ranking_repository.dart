import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_guard.dart';
import '../domain/ranking_entry.dart';

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => SupabaseRankingRepository(ref.watch(supabaseClientProvider)),
);

abstract interface class RankingRepository {
  /// Ranking global calculado no banco (top + linha do jogador).
  Future<RankingBoard> fetchRanking({int limit = 50});
}

class SupabaseRankingRepository implements RankingRepository {
  SupabaseRankingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<RankingBoard> fetchRanking({int limit = 50}) {
    return guardSupabase(() async {
      final rows =
          await _client.rpc('get_ranking', params: {'p_limit': limit})
              as List<dynamic>;
      return RankingBoard([
        for (final row in rows.cast<Map<String, dynamic>>())
          RankingEntry(
            position: (row['rank_position'] as num).toInt(),
            nickname: row['nickname'] as String,
            totalPoints: (row['total_points'] as num).toInt(),
            isMe: row['is_me'] as bool,
          ),
      ], limit: limit);
    });
  }
}

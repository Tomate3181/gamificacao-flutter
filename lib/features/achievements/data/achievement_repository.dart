import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_guard.dart';
import '../domain/achievement.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>(
  (ref) => SupabaseAchievementRepository(ref.watch(supabaseClientProvider)),
);

abstract interface class AchievementRepository {
  /// Todas as conquistas, marcando as que o jogador já desbloqueou.
  Future<List<Achievement>> fetchAll(String userId);
}

class SupabaseAchievementRepository implements AchievementRepository {
  SupabaseAchievementRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Achievement>> fetchAll(String userId) {
    return guardSupabase(() async {
      final catalog = await _client
          .from('achievements')
          .select('id, code, name, description, icon')
          .order('id');
      final unlocked = await _client
          .from('user_achievements')
          .select('achievement_id, unlocked_at')
          .eq('user_id', userId);

      final dates = {
        for (final row in unlocked)
          (row['achievement_id'] as num).toInt(): DateTime.parse(
            row['unlocked_at'] as String,
          ),
      };

      return [
        for (final row in catalog)
          Achievement(
            id: (row['id'] as num).toInt(),
            code: row['code'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            icon: row['icon'] as String,
            unlockedAt: dates[(row['id'] as num).toInt()],
          ),
      ];
    });
  }
}

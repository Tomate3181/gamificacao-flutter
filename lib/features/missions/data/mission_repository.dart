import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_guard.dart';
import '../../achievements/domain/achievement.dart';
import '../domain/mission.dart';

final missionRepositoryProvider = Provider<MissionRepository>(
  (ref) => SupabaseMissionRepository(ref.watch(supabaseClientProvider)),
);

abstract interface class MissionRepository {
  /// Catálogo de missões com o progresso do jogador.
  Future<List<MissionView>> fetchMissions(String userId);

  /// Inicia a missão. Retorna o progresso atual.
  Future<double> start(int missionId);

  /// Resgata a recompensa de uma missão que chegou na meta.
  Future<MissionClaim> claim(int missionId);
}

class SupabaseMissionRepository implements MissionRepository {
  SupabaseMissionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MissionView>> fetchMissions(String userId) {
    return guardSupabase(() async {
      final missions = await _client
          .from('missions')
          .select(
            'id, title, description, guidance, category, difficulty, '
            'points, energy_reward, goal_value, sort_order',
          )
          .order('sort_order');
      final mine = await _client
          .from('user_missions')
          .select('mission_id, status, progress')
          .eq('user_id', userId);

      final byMission = {
        for (final row in mine) (row['mission_id'] as num).toInt(): row,
      };

      return [
        for (final row in missions)
          _fromRow(row, byMission[(row['id'] as num).toInt()]),
      ];
    });
  }

  @override
  Future<double> start(int missionId) {
    return guardSupabase(() async {
      final result =
          await _client.rpc(
                'start_mission',
                params: {'p_mission_id': missionId},
              )
              as Map<String, dynamic>;
      return readNum(result['progress']);
    });
  }

  @override
  Future<MissionClaim> claim(int missionId) {
    return guardSupabase(() async {
      final result =
          await _client.rpc(
                'complete_mission',
                params: {'p_mission_id': missionId},
              )
              as Map<String, dynamic>;
      return MissionClaim(
        pointsEarned: (result['points_earned'] as num).toInt(),
        energyEarned: (result['energy_earned'] as num).toInt(),
        totalPoints: (result['total_points'] as num).toInt(),
        energy: readNum(result['energy']),
        achievements: UnlockedAchievement.listFrom(
          result['achievements_unlocked'],
        ),
      );
    });
  }

  MissionView _fromRow(Map<String, dynamic> row, Map<String, dynamic>? mine) {
    return MissionView(
      id: (row['id'] as num).toInt(),
      title: row['title'] as String,
      description: row['description'] as String,
      guidance: row['guidance'] as String,
      category: MissionCategory.fromName(row['category'] as String),
      difficulty: MissionDifficulty.fromName(row['difficulty'] as String),
      points: (row['points'] as num).toInt(),
      energyReward: (row['energy_reward'] as num).toInt(),
      goalValue: (row['goal_value'] as num).toInt(),
      sortOrder: (row['sort_order'] as num).toInt(),
      started: mine != null,
      completed: mine?['status'] == 'completed',
      progress: readNum(mine?['progress']),
    );
  }
}

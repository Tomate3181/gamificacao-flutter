import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_guard.dart';

final stepRepositoryProvider = Provider<StepRepository>(
  (ref) => SupabaseStepRepository(ref.watch(supabaseClientProvider)),
);

typedef StepSyncResult = ({
  int acceptedSteps,
  double energyGained,
  double energy,
});

abstract interface class StepRepository {
  /// Envia passos ao servidor, que converte em energia (com limite anti-trapaça).
  Future<StepSyncResult> sendSteps(int steps);
}

class SupabaseStepRepository implements StepRepository {
  SupabaseStepRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<StepSyncResult> sendSteps(int steps) {
    return guardSupabase(() async {
      final result =
          await _client.rpc('add_step_energy', params: {'p_steps': steps})
              as Map<String, dynamic>;
      return (
        acceptedSteps: (result['accepted_steps'] as num).toInt(),
        energyGained: readNum(result['energy_gained']),
        energy: readNum(result['energy']),
      );
    });
  }
}

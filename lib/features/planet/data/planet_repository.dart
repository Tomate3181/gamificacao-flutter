import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_guard.dart';
import '../domain/planet_models.dart';

final planetRepositoryProvider = Provider<PlanetRepository>(
  (ref) => SupabasePlanetRepository(ref.watch(supabaseClientProvider)),
);

typedef PlantResult = ({
  PlantedTree tree,
  double energy,
  int totalPoints,
  int reforestedSlots,
  bool planetCompleted,
});

abstract interface class PlanetRepository {
  /// Planeta atual do jogador, com árvores e catálogo de espécies.
  Future<PlanetState> fetchCurrent(String userId);

  Future<PlantResult> plantTree({
    required int slotIndex,
    required int speciesId,
  });
}

class SupabasePlanetRepository implements PlanetRepository {
  SupabasePlanetRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PlanetState> fetchCurrent(String userId) {
    return guardSupabase(() async {
      final currentId = await _client.rpc('ensure_current_planet') as String?;

      // Sem planeta ativo = todos concluídos; mostra o último.
      var query = _client
          .from('user_planets')
          .select('id, reforested_slots, completed_at, planets(*)')
          .eq('user_id', userId);
      if (currentId != null) query = query.eq('id', currentId);
      final row = await query
          .order('started_at', ascending: false)
          .limit(1)
          .single();

      final planetRow = row['planets'] as Map<String, dynamic>;
      final userPlanetId = row['id'] as String;

      final treeRows = await _client
          .from('user_trees')
          .select('id, species_id, slot_index, planted_at, ready_at')
          .eq('user_planet_id', userPlanetId);
      final speciesRows = await _client
          .from('tree_species')
          .select()
          .order('cost');

      final trees = [for (final tree in treeRows) _treeFromRow(tree)];

      return PlanetState(
        userPlanetId: userPlanetId,
        planet: Planet(
          id: (planetRow['id'] as num).toInt(),
          orderIndex: (planetRow['order_index'] as num).toInt(),
          name: planetRow['name'] as String,
          theme: planetRow['theme'] as String,
          totalSlots: (planetRow['total_slots'] as num).toInt(),
          baseCost: readNum(planetRow['base_cost']),
        ),
        reforestedSlots: (row['reforested_slots'] as num).toInt(),
        isCompleted: row['completed_at'] != null,
        trees: {for (final tree in trees) tree.slotIndex: tree},
        species: [
          for (final item in speciesRows)
            TreeSpecies(
              id: (item['id'] as num).toInt(),
              name: item['name'] as String,
              cost: (item['cost'] as num).toInt(),
              oxygenPerSec: readNum(item['oxygen_per_sec']),
              growSeconds: (item['grow_seconds'] as num).toInt(),
              rarity: item['rarity'] as String,
            ),
        ],
      );
    });
  }

  @override
  Future<PlantResult> plantTree({
    required int slotIndex,
    required int speciesId,
  }) {
    return guardSupabase(() async {
      final result =
          await _client.rpc(
                'plant_tree',
                params: {'p_slot_index': slotIndex, 'p_species_id': speciesId},
              )
              as Map<String, dynamic>;
      return (
        tree: _treeFromRow(result['tree'] as Map<String, dynamic>),
        energy: readNum(result['energy']),
        totalPoints: (result['total_points'] as num).toInt(),
        reforestedSlots: (result['reforested_slots'] as num).toInt(),
        planetCompleted: result['planet_completed'] as bool,
      );
    });
  }

  PlantedTree _treeFromRow(Map<String, dynamic> row) {
    return PlantedTree(
      id: row['id'] as String,
      speciesId: (row['species_id'] as num).toInt(),
      slotIndex: (row['slot_index'] as num).toInt(),
      plantedAt: DateTime.parse(row['planted_at'] as String),
      readyAt: DateTime.parse(row['ready_at'] as String),
    );
  }
}

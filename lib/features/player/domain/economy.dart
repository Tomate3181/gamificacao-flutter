import 'dart:math' as math;

/// Fórmulas da economia, espelhadas das funções SQL em
/// `supabase/migrations/20261027000001_core_economy.sql`.
///
/// Servem só para exibir custos e prévias na UI. Quem decide de verdade é o
/// servidor; se as duas versões divergirem, vale a do banco.
class Economy {
  const Economy._();

  static const stepsPerEnergy = 100;
  static const maxDiscount = 0.5;

  /// Custo em energia de uma espécie no planeta (private.tree_cost).
  static double treeCost({
    required int speciesCost,
    required double planetBaseCost,
    double costBonus = 0,
  }) {
    final discount = math.min(costBonus, maxDiscount);
    // Arredonda antes do ceil para evitar 57.000000001 virar 58.
    final raw = speciesCost * (planetBaseCost / 10) * (1 - discount);
    return (double.parse(raw.toStringAsFixed(6))).ceilToDouble();
  }

  /// Custo em oxigênio do próximo nível (private.upgrade_cost).
  static double upgradeCost({
    required double baseCost,
    required double multiplier,
    required int currentLevel,
  }) {
    final raw = baseCost * math.pow(multiplier, currentLevel);
    return (raw * 100).roundToDouble() / 100;
  }

  /// Energia gerada por uma quantidade de passos (add_step_energy).
  static double stepsToEnergy(int steps, {double energyBonus = 0}) {
    final raw = steps / stepsPerEnergy * (1 + energyBonus);
    return (raw * 100).roundToDouble() / 100;
  }
}

import 'dart:math' as math;

/// Fórmulas da economia, espelhadas das funções SQL em
/// `supabase/migrations/` (core_economy e polish).
///
/// Servem só para exibir custos e prévias na UI. Quem decide de verdade é o
/// servidor; se as duas versões divergirem, vale a do banco.
class Economy {
  const Economy._();

  static const stepsPerEnergy = 100;

  /// Teto do desconto de custo e da redução de crescimento (árvore de
  /// upgrades, fase 4).
  static const maxDiscount = 0.75;

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

  /// Tempo de crescimento com o bônus de Crescimento (plant_tree).
  static Duration growTime(int growSeconds, {double growthBonus = 0}) {
    final factor = 1 - math.min(growthBonus, maxDiscount);
    return Duration(milliseconds: (growSeconds * factor * 1000).round());
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

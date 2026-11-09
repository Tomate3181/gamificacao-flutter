import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/upgrade.dart';

/// Nome, cor, ícone e posição de cada ramo da árvore.
extension UpgradeBranchLabels on UpgradeBranch {
  String get label => switch (this) {
    UpgradeBranch.production => 'Produção',
    UpgradeBranch.growth => 'Crescimento',
    UpgradeBranch.cost => 'Custo',
    UpgradeBranch.energy => 'Energia',
    UpgradeBranch.offline => 'Noite',
  };

  Color get color => switch (this) {
    UpgradeBranch.production => AppColors.auroraTeal,
    UpgradeBranch.growth => AppColors.leafGreen,
    UpgradeBranch.cost => AppColors.gold,
    UpgradeBranch.energy => AppColors.hotPink,
    UpgradeBranch.offline => AppColors.auroraLilac,
  };

  /// Ângulo do ramo: o primeiro no topo, os outros a cada 72 graus.
  double get angle =>
      -math.pi / 2 + index * 2 * math.pi / UpgradeBranch.values.length;
}

/// Abertura entre os nós laterais do mesmo ramo (anéis 3 e 4).
const branchSlotSpread = math.pi / 10;

double nodeAngle(ShopItem item) =>
    item.branch.angle + item.branchSlot * branchSlotSpread;

IconData categoryIcon(UpgradeCategory category) => switch (category) {
  UpgradeCategory.cost => Icons.savings_outlined,
  UpgradeCategory.production => Icons.air,
  UpgradeCategory.energy => Icons.directions_walk,
  UpgradeCategory.growth => Icons.spa_outlined,
  UpgradeCategory.automation => Icons.precision_manufacturing_outlined,
  UpgradeCategory.offline => Icons.nightlight_outlined,
  UpgradeCategory.offlineHours => Icons.schedule,
};

/// Efeito de um valor de bônus. Ex.: "+20% de oxigênio".
String effectLabel(UpgradeCategory category, double value) {
  if (category == UpgradeCategory.offlineHours) {
    final hours = value % 1 == 0 ? value.toInt().toString() : '$value';
    return '+$hours h de coleta fora do app';
  }
  final percent = (value * 100).round();
  return switch (category) {
    UpgradeCategory.cost => '-$percent% no custo de plantio',
    UpgradeCategory.production => '+$percent% de oxigênio',
    UpgradeCategory.energy => '+$percent% de energia por passo',
    UpgradeCategory.growth => '-$percent% no tempo de crescimento',
    UpgradeCategory.offline => '+$percent% de oxigênio fora do app',
    UpgradeCategory.offlineHours => '',
    UpgradeCategory.automation => '${value.round()} drone(s)',
  };
}

/// Bônus atual do nó, para a linha verde do cartão.
String bonusLabel(ShopItem item) => item.level == 0
    ? 'Cada nível: ${effectLabel(item.category, item.effect)}'
    : 'Agora: ${effectLabel(item.category, item.bonus)}';

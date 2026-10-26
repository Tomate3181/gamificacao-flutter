import 'package:ecoplanet/core/theme/app_theme.dart';
import 'package:ecoplanet/features/planet/presentation/planet_page.dart';
import 'package:ecoplanet/widgets/upgrade_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('tocar numa região, escolher a espécie e plantar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final planetRepo = FakePlanetRepository();
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const PlanetPage())],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: gameOverrides(planet: planetRepo),
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Deserto Esquecido'), findsOneWidget);
    expect(find.text('0 de 100 regiões reflorestadas'), findsOneWidget);
    expect(find.text('50'), findsOneWidget); // energia
    expect(find.text('80'), findsOneWidget); // oxigênio

    await tester.tap(find.bySemanticsLabel('Região 1, poluída'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('O que plantar aqui?'), findsOneWidget);
    expect(find.text('Bambu'), findsOneWidget);

    await tester.tap(find.text('Muda'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(planetRepo.plantCalls, [(0, 1)]);
    expect(find.text('1 de 100 regiões reflorestadas'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.bySemanticsLabel('Região 1, reflorestada'), findsOneWidget);

    // Desmonta para cancelar timers e animações.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('UpgradeTile desabilita a compra sem oxigênio', (tester) async {
    var bought = 0;
    Widget tile({required bool canAfford, int level = 1}) => MaterialApp(
      home: Scaffold(
        body: UpgradeTile(
          icon: Icons.air,
          name: 'Fotossíntese Turbo',
          description: 'Aumenta o oxigênio.',
          level: level,
          maxLevel: 10,
          bonusLabel: '+10% de oxigênio',
          costLabel: '75 O₂',
          canAfford: canAfford,
          onBuy: () => bought++,
        ),
      ),
    );

    await tester.pumpWidget(tile(canAfford: false));
    expect(find.text('Oxigênio insuficiente · 75 O₂'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(bought, 0);

    await tester.pumpWidget(tile(canAfford: true));
    await tester.tap(find.text('Melhorar por 75 O₂'));
    expect(bought, 1);

    await tester.pumpWidget(tile(canAfford: true, level: 10));
    expect(find.text('Nível máximo'), findsOneWidget);
  });
}

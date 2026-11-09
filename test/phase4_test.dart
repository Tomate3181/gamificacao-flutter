import 'package:ecoplanet/core/theme/app_theme.dart';
import 'package:ecoplanet/features/planet/domain/planet_models.dart';
import 'package:ecoplanet/features/planet/presentation/planet_completed_dialog.dart';
import 'package:ecoplanet/features/planet/presentation/planet_controller.dart';
import 'package:ecoplanet/features/player/domain/economy.dart';
import 'package:ecoplanet/features/player/domain/offline_report.dart';
import 'package:ecoplanet/features/player/presentation/offline_progress_controller.dart';
import 'package:ecoplanet/features/player/presentation/player_controller.dart';
import 'package:ecoplanet/features/shop/domain/upgrade.dart';
import 'package:ecoplanet/features/shop/presentation/shop_page.dart';
import 'package:ecoplanet/features/shop/presentation/upgrade_labels.dart';
import 'package:ecoplanet/widgets/planet_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fakes.dart';

ShopItem node(
  int id, {
  int? parent,
  int level = 0,
  int max = 5,
  UpgradeCategory category = UpgradeCategory.cost,
  double effect = 0.04,
  double baseCost = 50,
}) => ShopItem(
  id: id,
  category: category,
  branch: UpgradeBranch.cost,
  name: 'Nó $id',
  description: '',
  maxLevel: max,
  baseCost: baseCost,
  costMultiplier: 1.5,
  effect: effect,
  level: level,
  tier: parent == null ? 1 : 2,
  parentId: parent,
);

OfflineReport report({int minutes = 120, double gained = 300}) => OfflineReport(
  away: Duration(minutes: minutes),
  counted: Duration(minutes: minutes.clamp(0, 480)),
  offlineRate: 0.5,
  oxygenGained: gained,
  oxygen: 80 + gained,
);

void main() {
  group('UpgradeTree', () {
    test('filho fica bloqueado até o pai ter 1 nível', () {
      final locked = UpgradeTree([node(1), node(2, parent: 1)]);
      expect(locked.statusOf(locked.byId(2)!), UpgradeNodeStatus.locked);
      expect(locked.statusOf(locked.byId(1)!), UpgradeNodeStatus.available);

      final open = UpgradeTree([node(1, level: 1), node(2, parent: 1)]);
      expect(open.statusOf(open.byId(1)!), UpgradeNodeStatus.owned);
      expect(open.statusOf(open.byId(2)!), UpgradeNodeStatus.available);
    });

    test('bônus soma todos os nós da categoria, de qualquer ramo', () {
      final tree = UpgradeTree([
        node(1, level: 5, max: 5),
        node(2, parent: 1, level: 2, effect: 0.03),
        node(3, parent: 1, level: 1, category: UpgradeCategory.energy),
      ]);
      expect(tree.bonus(UpgradeCategory.cost), closeTo(0.26, 1e-9));
      expect(tree.statusOf(tree.byId(1)!), UpgradeNodeStatus.maxed);
      expect(tree.ownedLevels, 8);
    });

    test('sugere o nó liberado mais barato', () {
      final tree = UpgradeTree([
        node(1, level: 1, baseCost: 50),
        node(2, parent: 1, baseCost: 60),
        node(3, parent: 2, baseCost: 1),
      ]);
      // Nó 1 no nível 1 custa 75; o 2 custa 60; o 3 está bloqueado.
      expect(tree.suggested()?.id, 2);
    });

    test('ramos ficam a 72 graus e as horas offline têm rótulo próprio', () {
      expect(UpgradeBranch.production.angle, closeTo(-1.5708, 1e-4));
      expect(
        UpgradeBranch.growth.angle - UpgradeBranch.production.angle,
        closeTo(1.2566, 1e-4),
      );
      expect(
        effectLabel(UpgradeCategory.offlineHours, 4),
        '+4 h de coleta fora do app',
      );
      expect(effectLabel(UpgradeCategory.offline, 0.15), contains('15%'));
    });
  });

  group('economia e planeta', () {
    test('crescimento com bônus e teto de 75%', () {
      expect(Economy.growTime(60, growthBonus: 0.25).inSeconds, 45);
      expect(Economy.growTime(100, growthBonus: 2).inSeconds, 25);
    });

    test('grade do planeta fica quase quadrada', () {
      expect(PlanetView.autoColumns(10), 5); // 5 x 2, sem sobra
      expect(PlanetView.autoColumns(15), 5); // 5 x 3
      expect(PlanetView.autoColumns(51), 9); // 9 x 6, sobram 3
      expect(PlanetView.autoColumns(200), 15);
    });
  });

  group('OfflineReport', () {
    test('só mostra depois de 5 minutos e com oxigênio ganho', () {
      expect(report(minutes: 3).isWorthShowing, isFalse);
      expect(report(gained: 0).isWorthShowing, isFalse);
      expect(report().isWorthShowing, isTrue);
      expect(report(minutes: 600).hitLimit, isTrue);
    });

    test('formata o tempo fora', () {
      expect(formatAway(const Duration(minutes: 45)), '45 min');
      expect(formatAway(const Duration(hours: 2, minutes: 15)), '2 h 15 min');
      expect(formatAway(const Duration(hours: 3)), '3 h');
      expect(formatAway(const Duration(days: 3)), '3 dias');
    });
  });

  group('controllers', () {
    late FakePlayerRepository player;
    late FakePlanetRepository planet;
    late ProviderContainer container;

    setUp(() {
      player = FakePlayerRepository();
      planet = FakePlanetRepository();
      container = ProviderContainer(
        overrides: gameOverrides(player: player, planet: planet),
      );
      container
        ..listen(playerControllerProvider, (_, _) {})
        ..listen(planetControllerProvider, (_, _) {})
        ..listen(offlineProgressControllerProvider, (_, _) {});
    });

    tearDown(() => container.dispose());

    test('coleta offline aplica o oxigênio e guarda o aviso', () async {
      player.offlineReport = report(gained: 300);
      await container
          .read(offlineProgressControllerProvider.notifier)
          .collect();

      expect(container.read(playerControllerProvider).value!.oxygen, 380);
      expect(
        container.read(offlineProgressControllerProvider)?.oxygenGained,
        300,
      );

      container.read(offlineProgressControllerProvider.notifier).dismiss();
      expect(container.read(offlineProgressControllerProvider), isNull);
    });

    test('pausa curta não mostra aviso', () async {
      player.offlineReport = report(minutes: 1, gained: 20);
      await container
          .read(offlineProgressControllerProvider.notifier)
          .collect();

      expect(player.offlineCalls, 1);
      expect(container.read(offlineProgressControllerProvider), isNull);
      expect(container.read(playerControllerProvider).value!.oxygen, 100);
    });

    test(
      'última árvore conclui o planeta e a viagem carrega o próximo',
      () async {
        await container.read(playerControllerProvider.future);
        await container.read(planetControllerProvider.future);
        planet.completeWith = const PlanetPreview(
          orderIndex: 2,
          name: 'Floresta Adormecida',
          theme: 'forest',
          totalSlots: 15,
        );

        final outcome = await container
            .read(planetControllerProvider.notifier)
            .plant(slotIndex: 0, speciesId: 1);

        expect(outcome.completion?.pointsEarned, 100);
        expect(outcome.completion?.next?.name, 'Floresta Adormecida');
        expect(
          container.read(planetControllerProvider).value!.isCompleted,
          isTrue,
        );

        planet.planet = const Planet(
          id: 2,
          orderIndex: 2,
          name: 'Floresta Adormecida',
          theme: 'forest',
          totalSlots: 15,
          baseCost: 13,
        );
        await container.read(planetControllerProvider.notifier).travelToNext();
        final next = container.read(planetControllerProvider).value!;
        expect(next.planet.name, 'Floresta Adormecida');
        expect(next.isCompleted, isFalse);
      },
    );
  });

  testWidgets('diálogo de planeta salvo mostra pontos e o próximo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: PlanetCompletedDialog(
            completion: PlanetCompletion(
              planetName: 'Deserto Esquecido',
              pointsEarned: 100,
              next: PlanetPreview(
                orderIndex: 2,
                name: 'Floresta Adormecida',
                theme: 'forest',
                totalSlots: 15,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Planeta salvo!'), findsOneWidget);
    expect(find.text('+100 pontos'), findsOneWidget);
    expect(find.text('15 regiões poluídas'), findsOneWidget);
    expect(find.text('Seguir viagem'), findsOneWidget);
  });

  testWidgets('loja: árvore mostra nós e explica o bloqueio', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const ShopPage())],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: gameOverrides(),
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Sugerido ao abrir: a raiz mais barata.
    expect(find.text('Sementes Eficientes'), findsOneWidget);
    expect(find.text('0 de 13 níveis'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Solo Fértil')));
    await tester.pump();

    expect(find.text('Solo Fértil'), findsOneWidget);
    expect(find.text('Compre Sementes Eficientes antes'), findsOneWidget);
  });
}

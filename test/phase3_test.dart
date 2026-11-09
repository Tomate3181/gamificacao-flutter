import 'package:ecoplanet/core/errors/game_failure.dart';
import 'package:ecoplanet/core/theme/app_theme.dart';
import 'package:ecoplanet/features/achievements/presentation/achievements_page.dart';
import 'package:ecoplanet/features/missions/domain/mission.dart';
import 'package:ecoplanet/features/missions/presentation/mission_details_page.dart';
import 'package:ecoplanet/features/missions/presentation/missions_controller.dart';
import 'package:ecoplanet/features/player/presentation/player_controller.dart';
import 'package:ecoplanet/features/ranking/domain/ranking_entry.dart';
import 'package:ecoplanet/features/ranking/presentation/ranking_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fakes.dart';

MissionView mission({
  int id = 1,
  int goal = 10,
  bool started = false,
  bool completed = false,
  double progress = 0,
  int sortOrder = 1,
}) => MissionView(
  id: id,
  title: 'Missão $id',
  description: '',
  guidance: '',
  category: MissionCategory.planting,
  difficulty: MissionDifficulty.easy,
  points: 10,
  energyReward: 5,
  goalValue: goal,
  sortOrder: sortOrder,
  started: started,
  completed: completed,
  progress: progress,
);

Widget app(Widget page) {
  final router = GoRouter(
    initialLocation: '/page',
    routes: [
      GoRoute(path: '/page', builder: (_, _) => page),
      GoRoute(path: '/missions', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
    ],
  );
  return ProviderScope(
    overrides: gameOverrides(),
    child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
  );
}

void main() {
  group('MissionView', () {
    test('status vem do início, do progresso e da conclusão', () {
      expect(mission().status, MissionStatus.available);
      expect(
        mission(started: true, progress: 3).status,
        MissionStatus.inProgress,
      );
      expect(
        mission(started: true, progress: 10).status,
        MissionStatus.readyToClaim,
      );
      expect(
        mission(started: true, completed: true, progress: 10).status,
        MissionStatus.completed,
      );
      expect(mission(started: true, progress: 5).progressRatio, 0.5);
    });

    test('lista põe prontas primeiro e concluídas por último', () {
      final sorted = sortMissions([
        mission(id: 1, completed: true, started: true, sortOrder: 1),
        mission(id: 2, sortOrder: 2),
        mission(id: 3, started: true, progress: 1, sortOrder: 3),
        mission(id: 4, started: true, progress: 10, sortOrder: 4),
      ]);
      expect(sorted.map((m) => m.id), [4, 3, 2, 1]);
    });
  });

  test('ranking separa pódio e mostra o jogador fora do top', () {
    final board = RankingBoard(FakeRankingRepository().rows, limit: 4);
    expect(board.podium.map((e) => e.nickname), ['Bia', 'Caio', 'Duda']);
    expect(board.rest.single.nickname, 'Eva');
    expect(board.me?.position, 9);
    expect(board.meOutsideTop, isTrue);
  });

  group('MissionsController', () {
    late FakeMissionRepository repo;
    late ProviderContainer container;

    setUp(() async {
      repo = FakeMissionRepository();
      container = ProviderContainer(overrides: gameOverrides(missions: repo));
      container
        ..listen(missionsControllerProvider, (_, _) {})
        ..listen(playerControllerProvider, (_, _) {})
        ..listen(featuredMissionProvider, (_, _) {});
      await container.read(playerControllerProvider.future);
      await container.read(missionsControllerProvider.future);
    });

    tearDown(() => container.dispose());

    test('missão em destaque é a pronta para resgatar', () {
      expect(container.read(featuredMissionProvider)?.id, 1);
    });

    test('resgatar conclui, aplica recompensa e muda o destaque', () async {
      final outcome = await container
          .read(missionsControllerProvider.notifier)
          .claim(1);

      expect(outcome.failure, isNull);
      expect(outcome.claim?.achievements.single.name, 'Primeiros passos');
      final missions = container.read(missionsControllerProvider).value!;
      expect(
        missions.firstWhere((m) => m.id == 1).status,
        MissionStatus.completed,
      );
      final player = container.read(playerControllerProvider).value!;
      expect(player.totalPoints, 30);
      expect(player.energy, 70);
      expect(container.read(featuredMissionProvider)?.id, 3);
    });

    test('falha no resgate devolve a mensagem e não conclui', () async {
      repo.claimFailure = GameFailure.fromCode('mission_not_ready');
      final outcome = await container
          .read(missionsControllerProvider.notifier)
          .claim(3);

      expect(outcome.failure?.code, 'mission_not_ready');
      expect(container.read(playerControllerProvider).value!.totalPoints, 0);
    });

    test('iniciar marca a missão como em andamento', () async {
      final failure = await container
          .read(missionsControllerProvider.notifier)
          .start(2);

      expect(failure, isNull);
      expect(repo.startCalls, [2]);
      final started = container
          .read(missionsControllerProvider)
          .value!
          .firstWhere((m) => m.id == 2);
      expect(started.status, MissionStatus.inProgress);
    });
  });

  testWidgets('detalhes da missão: resgatar mostra recompensa e conquista', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const MissionDetailsPage(missionId: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Aquecendo'), findsOneWidget);
    expect(find.text('200 de 200 passos'), findsOneWidget);

    await tester.tap(find.text('Resgatar recompensa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Recompensa resgatada'), findsOneWidget);
    expect(
      find.textContaining('Conquista desbloqueada: Primeiros passos'),
      findsOneWidget,
    );
    expect(find.text('Missão concluída'), findsOneWidget);
  });

  testWidgets('detalhes de missão inexistente mostram aviso', (tester) async {
    await tester.pumpWidget(app(const MissionDetailsPage(missionId: 999)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Missão não encontrada.'), findsOneWidget);
  });

  testWidgets('ranking mostra top 3 e a posição do jogador', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const RankingPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sua posição'), findsOneWidget);
    expect(find.text('Lumi Fã (você)'), findsOneWidget);
    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('Top 3'), findsOneWidget);
    expect(find.text('Eva'), findsOneWidget);
  });

  testWidgets('conquistas mostram bloqueadas com a condição', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const AchievementsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1 de 2 desbloqueadas'), findsOneWidget);
    expect(find.text('Conclua cinco missões.'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });
}

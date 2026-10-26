import 'package:ecoplanet/core/errors/game_failure.dart';
import 'package:ecoplanet/features/planet/presentation/planet_controller.dart';
import 'package:ecoplanet/features/player/presentation/player_controller.dart';
import 'package:ecoplanet/features/shop/domain/upgrade.dart';
import 'package:ecoplanet/features/shop/presentation/shop_controller.dart';
import 'package:ecoplanet/features/steps/presentation/step_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  late FakePlanetRepository planetRepo;
  late FakeShopRepository shopRepo;
  late FakeStepRepository stepRepo;
  late ProviderContainer container;

  setUp(() async {
    planetRepo = FakePlanetRepository();
    shopRepo = FakeShopRepository();
    stepRepo = FakeStepRepository();
    container = ProviderContainer(
      overrides: gameOverrides(
        planet: planetRepo,
        shop: shopRepo,
        steps: stepRepo,
      ),
    );
    // No Riverpod 3, provider sem ouvinte fica pausado: mantém todos ativos.
    container
      ..listen(playerControllerProvider, (_, _) {})
      ..listen(planetControllerProvider, (_, _) {})
      ..listen(shopControllerProvider, (_, _) {})
      ..listen(stepControllerProvider, (_, _) {});
    await container.read(playerControllerProvider.future);
  });

  tearDown(() => container.dispose());

  test(
    'plantar atualiza o planeta e a energia com os valores do servidor',
    () async {
      await container.read(planetControllerProvider.future);

      final outcome = await container
          .read(planetControllerProvider.notifier)
          .plant(slotIndex: 7, speciesId: 1);

      expect(outcome.failure, isNull);
      expect(planetRepo.plantCalls, [(7, 1)]);
      final planet = container.read(planetControllerProvider).value!;
      expect(planet.trees.keys, contains(7));
      expect(planet.reforestedSlots, 1);
      expect(container.read(playerControllerProvider).value!.energy, 40);
      expect(container.read(plantingSlotProvider), isNull);
    },
  );

  test('falha no plantio não muda o estado e devolve a mensagem', () async {
    await container.read(planetControllerProvider.future);
    planetRepo.plantFailure = GameFailure.fromCode('not_enough_energy');

    final outcome = await container
        .read(planetControllerProvider.notifier)
        .plant(slotIndex: 3, speciesId: 2);

    expect(outcome.failure?.code, 'not_enough_energy');
    expect(container.read(planetControllerProvider).value!.trees, isEmpty);
    expect(container.read(playerControllerProvider).value!.energy, 50);
  });

  test('comprar upgrade sobe o nível e atualiza o oxigênio', () async {
    await container.read(shopControllerProvider.future);

    final failure = await container
        .read(shopControllerProvider.notifier)
        .buy(3);

    expect(failure, isNull);
    expect(container.read(shopControllerProvider).value!.single.level, 1);
    expect(container.read(playerControllerProvider).value!.oxygen, 30);
    expect(
      container.read(upgradeBonusProvider(UpgradeCategory.cost)),
      closeTo(0.05, 1e-9),
    );
  });

  test('custo da espécie usa o desconto do upgrade Custo', () async {
    final planet = await container.read(planetControllerProvider.future);
    await container.read(shopControllerProvider.future);
    final bambu = planet.species[1];

    expect(container.read(speciesCostProvider(bambu)), 25);
    await container.read(shopControllerProvider.notifier).buy(3);
    expect(container.read(speciesCostProvider(bambu)), 24);
  });

  test('modo demo envia passos e informa o limite do servidor', () async {
    stepRepo.acceptLimit = 200;
    final result = await container
        .read(stepControllerProvider.notifier)
        .simulateSteps(500);

    expect(result.accepted, 200);
    expect(result.failure, isNull);
    expect(container.read(stepControllerProvider).sessionSteps, 200);
    expect(container.read(playerControllerProvider).value!.energy, 52);
  });

  test('sem pedômetro o status fica "sem suporte"', () async {
    container.read(stepControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(stepControllerProvider).status,
      StepSensorStatus.unsupported,
    );
  });
}

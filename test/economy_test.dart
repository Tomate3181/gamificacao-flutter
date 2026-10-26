import 'package:ecoplanet/core/errors/game_failure.dart';
import 'package:ecoplanet/core/utils/number_format.dart';
import 'package:ecoplanet/features/player/domain/economy.dart';
import 'package:ecoplanet/features/steps/domain/step_batcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Os mesmos valores foram conferidos contra as funções SQL.
  group('Economy', () {
    test('custo da árvore com desconto e multiplicador do planeta', () {
      expect(Economy.treeCost(speciesCost: 10, planetBaseCost: 10), 10);
      expect(
        Economy.treeCost(speciesCost: 60, planetBaseCost: 10, costBonus: 0.05),
        57,
      );
      // Planeta 2 custa 30% a mais.
      expect(Economy.treeCost(speciesCost: 10, planetBaseCost: 13), 13);
      // Desconto máximo de 50%.
      expect(
        Economy.treeCost(speciesCost: 100, planetBaseCost: 10, costBonus: 0.9),
        50,
      );
    });

    test('upgrade começa em 50 e cresce 1,5x por nível', () {
      double cost(int level) => Economy.upgradeCost(
        baseCost: 50,
        multiplier: 1.5,
        currentLevel: level,
      );
      expect(cost(0), 50);
      expect(cost(1), 75);
      expect(cost(2), 112.5);
      expect(cost(9), 1922.17);
    });

    test('100 passos = 1 energia, com bônus', () {
      expect(Economy.stepsToEnergy(500), 5);
      expect(Economy.stepsToEnergy(150), 1.5);
      expect(Economy.stepsToEnergy(1000, energyBonus: 0.2), 12);
    });
  });

  group('StepBatcher', () {
    test('primeira leitura só define a base', () {
      final batcher = StepBatcher();
      expect(batcher.addReading(5000), 0);
      expect(batcher.pending, 0);
    });

    test('acumula diferenças e pede envio no limite', () {
      final batcher = StepBatcher(flushThreshold: 100)..addReading(1000);
      batcher.addReading(1060);
      expect(batcher.pending, 60);
      expect(batcher.shouldFlush, isFalse);
      batcher.addReading(1120);
      expect(batcher.shouldFlush, isTrue);
      expect(batcher.takePending(), 120);
      expect(batcher.pending, 0);
    });

    test('reinício do aparelho conta a partir do zero', () {
      final batcher = StepBatcher()..addReading(8000);
      expect(batcher.addReading(30), 30);
    });

    test('devolve passos quando o envio falha', () {
      final batcher = StepBatcher()..addReading(0);
      batcher.addReading(50);
      final steps = batcher.takePending();
      batcher.restore(steps);
      expect(batcher.pending, 50);
    });
  });

  group('GameFailure', () {
    test('traduz códigos das RPCs', () {
      expect(
        GameFailure.fromCode('not_enough_energy').message,
        contains('Energia insuficiente'),
      );
      expect(GameFailure.fromCode('slot_taken').code, 'slot_taken');
      expect(GameFailure.fromCode('qualquer coisa').code, 'unknown');
    });
  });

  group('formatResource', () {
    test('formata no padrão brasileiro', () {
      expect(formatResource(5), '5');
      expect(formatResource(12.5), '12,5');
      expect(formatResource(1250), '1.250');
      expect(formatResource(1234567.8), '1.234.567');
    });
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

final stepSensorProvider = Provider<StepSensor>((ref) => PedometerStepSensor());

/// Fonte de passos do aparelho.
abstract interface class StepSensor {
  /// Falso na web e no desktop, onde não há pedômetro.
  bool get isSupported;

  Future<bool> requestPermission();

  /// Total acumulado de passos informado pelo sistema.
  Stream<int> get cumulativeSteps;
}

class PedometerStepSensor implements StepSensor {
  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> requestPermission() async {
    // No iOS o sistema pede a permissão sozinho na primeira leitura.
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  @override
  Stream<int> get cumulativeSteps =>
      Pedometer.stepCountStream.map((event) => event.steps);
}

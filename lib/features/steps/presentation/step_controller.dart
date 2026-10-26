import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/game_failure.dart';
import '../../auth/presentation/session_providers.dart';
import '../../player/presentation/player_controller.dart';
import '../data/pedometer_source.dart';
import '../data/step_repository.dart';
import '../domain/step_batcher.dart';

enum StepSensorStatus { idle, starting, active, unsupported, denied, error }

class StepState {
  const StepState({this.status = StepSensorStatus.idle, this.sessionSteps = 0});

  final StepSensorStatus status;

  /// Passos aceitos pelo servidor nesta sessão do app.
  final int sessionSteps;

  StepState copyWith({StepSensorStatus? status, int? sessionSteps}) {
    return StepState(
      status: status ?? this.status,
      sessionSteps: sessionSteps ?? this.sessionSteps,
    );
  }
}

/// Resultado do "simular passos" para a UI mostrar.
typedef SimulationResult = ({
  int requested,
  int accepted,
  double energyGained,
  GameFailure? failure,
});

/// Lê o pedômetro, junta os passos e envia ao servidor a cada 30 s
/// (ou a cada 200 passos). Também oferece o modo demo.
final stepControllerProvider = NotifierProvider<StepController, StepState>(
  StepController.new,
);

class StepController extends Notifier<StepState> {
  static const flushInterval = Duration(seconds: 30);
  static const demoSteps = 500;

  StepBatcher _batcher = StepBatcher();
  StreamSubscription<int>? _subscription;
  Timer? _timer;
  bool _sending = false;

  @override
  StepState build() {
    final userId = ref.watch(currentUserIdProvider).value;
    ref.onDispose(_stop);
    // Cada usuário começa com um lote novo.
    _batcher = StepBatcher();
    _sending = false;
    if (userId == null) return const StepState();

    Future.microtask(_start);
    return const StepState(status: StepSensorStatus.starting);
  }

  Future<void> _start() async {
    final sensor = ref.read(stepSensorProvider);
    if (!sensor.isSupported) {
      state = state.copyWith(status: StepSensorStatus.unsupported);
      return;
    }
    final granted = await sensor.requestPermission();
    if (!ref.mounted) return;
    if (!granted) {
      state = state.copyWith(status: StepSensorStatus.denied);
      return;
    }

    _subscription = sensor.cumulativeSteps.listen(
      (cumulative) {
        _batcher.addReading(cumulative);
        if (_batcher.shouldFlush) flush();
      },
      onError: (_) {
        if (ref.mounted) state = state.copyWith(status: StepSensorStatus.error);
      },
    );
    _timer = Timer.periodic(flushInterval, (_) => flush());
    state = state.copyWith(status: StepSensorStatus.active);
  }

  void _stop() {
    _subscription?.cancel();
    _timer?.cancel();
  }

  /// Envia os passos pendentes do pedômetro.
  Future<void> flush() async {
    if (_sending || _batcher.pending == 0) return;
    _sending = true;
    final steps = _batcher.takePending();
    try {
      await _send(steps);
    } on GameFailure {
      _batcher.restore(steps);
    } finally {
      _sending = false;
    }
  }

  /// Modo demo: envia passos simulados pelo mesmo caminho do pedômetro.
  Future<SimulationResult> simulateSteps([int steps = demoSteps]) async {
    try {
      final result = await _send(steps);
      return (
        requested: steps,
        accepted: result.acceptedSteps,
        energyGained: result.energyGained,
        failure: null,
      );
    } on GameFailure catch (failure) {
      return (
        requested: steps,
        accepted: 0,
        energyGained: 0.0,
        failure: failure,
      );
    }
  }

  Future<StepSyncResult> _send(int steps) async {
    final result = await ref.read(stepRepositoryProvider).sendSteps(steps);
    if (ref.mounted) {
      state = state.copyWith(
        sessionSteps: state.sessionSteps + result.acceptedSteps,
      );
      ref
          .read(playerControllerProvider.notifier)
          .applyServerValues(energy: result.energy);
    }
    return result;
  }
}

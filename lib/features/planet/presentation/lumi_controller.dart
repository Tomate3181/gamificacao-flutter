import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/lumi_sprite.dart';

class LumiState {
  const LumiState({this.mood = LumiMood.wandering, this.targetSlot});

  final LumiMood mood;

  /// Região para onde a Lumi vai (só no estado seguindo).
  final int? targetSlot;
}

/// Decide o estado da Lumi (seção 10 do GDD). Estados temporários voltam
/// sozinhos para "vagando".
final lumiControllerProvider = NotifierProvider<LumiController, LumiState>(
  LumiController.new,
);

class LumiController extends Notifier<LumiState> {
  static const followDuration = Duration(seconds: 4);
  static const happyDuration = Duration(milliseconds: 2200);
  static const collectDuration = Duration(milliseconds: 1600);

  Timer? _timer;

  @override
  LumiState build() {
    ref.onDispose(() => _timer?.cancel());
    return const LumiState();
  }

  void wander() {
    _timer?.cancel();
    state = const LumiState();
  }

  /// Vai até a região tocada e fica ao lado da árvore.
  void follow(int slot) => _setFor(
    LumiState(mood: LumiMood.following, targetSlot: slot),
    followDuration,
  );

  /// Árvore terminou de crescer ou planeta concluído.
  void celebrate() => _setFor(
    LumiState(mood: LumiMood.happy, targetSlot: state.targetSlot),
    happyDuration,
  );

  /// Oxigênio coletado. Não interrompe a comemoração.
  void collect() {
    if (state.mood == LumiMood.happy) return;
    _setFor(
      LumiState(mood: LumiMood.collecting, targetSlot: state.targetSlot),
      collectDuration,
    );
  }

  void _setFor(LumiState next, Duration duration) {
    _timer?.cancel();
    state = next;
    _timer = Timer(duration, wander);
  }
}

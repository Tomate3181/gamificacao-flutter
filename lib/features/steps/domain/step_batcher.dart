/// Acumula os passos do pedômetro para enviar em lotes ao servidor.
///
/// O pedômetro informa um total acumulado (desde o boot do aparelho). A
/// primeira leitura só define a base: passos dados com o app fechado não
/// contam (progresso offline fica para a fase 4).
class StepBatcher {
  StepBatcher({this.flushThreshold = 200});

  final int flushThreshold;

  int? _lastReading;
  int _pending = 0;

  int get pending => _pending;

  bool get shouldFlush => _pending >= flushThreshold;

  /// Registra uma leitura acumulada e retorna quantos passos novos ela trouxe.
  int addReading(int cumulative) {
    final last = _lastReading;
    _lastReading = cumulative;
    if (last == null) return 0;

    // Contador menor que o anterior = aparelho reiniciou; conta do zero.
    final delta = cumulative >= last ? cumulative - last : cumulative;
    _pending += delta;
    return delta;
  }

  /// Retira os passos pendentes para envio.
  int takePending() {
    final steps = _pending;
    _pending = 0;
    return steps;
  }

  /// Devolve passos que não foram enviados (falha de rede).
  void restore(int steps) => _pending += steps;
}

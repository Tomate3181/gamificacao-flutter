/// Resultado da coleta de oxigênio do tempo fora do app
/// (RPC `collect_offline_oxygen`).
class OfflineReport {
  const OfflineReport({
    required this.away,
    required this.counted,
    required this.offlineRate,
    required this.oxygenGained,
    required this.oxygen,
  });

  /// Pausas curtas (trocar de aba, atender o telefone) não merecem aviso.
  static const minAwayToShow = Duration(minutes: 5);

  /// Tempo total longe do app.
  final Duration away;

  /// Parte do tempo que rendeu oxigênio (tem teto, em horas).
  final Duration counted;

  /// Rendimento fora do app, de 0 a 1 (0.5 = 50%).
  final double offlineRate;
  final double oxygenGained;

  /// Oxigênio total depois da coleta.
  final double oxygen;

  bool get isWorthShowing => away >= minAwayToShow && oxygenGained > 0;

  /// O tempo fora passou do teto e parte dele não rendeu.
  bool get hitLimit => away > counted;
}

/// "2 h 15 min", "45 min", "3 dias".
String formatAway(Duration duration) {
  if (duration.inDays >= 2) return '${duration.inDays} dias';
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return '${duration.inMinutes} min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}

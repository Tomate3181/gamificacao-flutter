/// Recursos do jogador (linha de `profiles`).
class PlayerStats {
  const PlayerStats({
    required this.nickname,
    required this.energy,
    required this.oxygen,
    required this.totalPoints,
  });

  final String nickname;
  final double energy;
  final double oxygen;
  final int totalPoints;

  PlayerStats copyWith({double? energy, double? oxygen, int? totalPoints}) {
    return PlayerStats(
      nickname: nickname,
      energy: energy ?? this.energy,
      oxygen: oxygen ?? this.oxygen,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

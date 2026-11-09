/// Números do jogador para o perfil e a home.
class ProfileSummary {
  const ProfileSummary({
    required this.missionsCompleted,
    required this.achievementsUnlocked,
    required this.achievementsTotal,
    required this.planetsCompleted,
    required this.treesPlanted,
  });

  final int missionsCompleted;
  final int achievementsUnlocked;
  final int achievementsTotal;
  final int planetsCompleted;
  final int treesPlanted;
}

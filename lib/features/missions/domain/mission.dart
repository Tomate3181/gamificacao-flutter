import '../../achievements/domain/achievement.dart';

enum MissionCategory {
  walking('Caminhada', 'passos'),
  planting('Plantio', 'árvores'),
  oxygen('Oxigênio', 'O₂'),
  upgrades('Melhorias', 'upgrades');

  const MissionCategory(this.label, this.unit);

  final String label;

  /// Unidade do objetivo, para "150 de 200 passos".
  final String unit;

  static MissionCategory fromName(String name) =>
      values.firstWhere((value) => value.name == name);
}

enum MissionDifficulty {
  easy('Fácil'),
  medium('Média'),
  hard('Difícil');

  const MissionDifficulty(this.label);

  final String label;

  static MissionDifficulty fromName(String name) =>
      values.firstWhere((value) => value.name == name);
}

/// Situação da missão para o jogador.
enum MissionStatus {
  available('Disponível'),
  inProgress('Em andamento'),
  readyToClaim('Pronta para resgatar'),
  completed('Concluída');

  const MissionStatus(this.label);

  final String label;
}

/// Missão do catálogo junto com o progresso do jogador.
class MissionView {
  const MissionView({
    required this.id,
    required this.title,
    required this.description,
    required this.guidance,
    required this.category,
    required this.difficulty,
    required this.points,
    required this.energyReward,
    required this.goalValue,
    required this.sortOrder,
    this.started = false,
    this.completed = false,
    this.progress = 0,
  });

  final int id;
  final String title;
  final String description;
  final String guidance;
  final MissionCategory category;
  final MissionDifficulty difficulty;
  final int points;
  final int energyReward;
  final int goalValue;
  final int sortOrder;

  final bool started;
  final bool completed;

  /// Progresso desde que a missão foi iniciada (o servidor para na meta).
  final double progress;

  MissionStatus get status {
    if (completed) return MissionStatus.completed;
    if (!started) return MissionStatus.available;
    return progress >= goalValue
        ? MissionStatus.readyToClaim
        : MissionStatus.inProgress;
  }

  double get progressRatio {
    if (completed) return 1;
    if (goalValue <= 0) return 0;
    return (progress / goalValue).clamp(0.0, 1.0);
  }

  MissionView copyWith({bool? started, bool? completed, double? progress}) {
    return MissionView(
      id: id,
      title: title,
      description: description,
      guidance: guidance,
      category: category,
      difficulty: difficulty,
      points: points,
      energyReward: energyReward,
      goalValue: goalValue,
      sortOrder: sortOrder,
      started: started ?? this.started,
      completed: completed ?? this.completed,
      progress: progress ?? this.progress,
    );
  }
}

/// Ordem da lista: prontas para resgatar, em andamento, disponíveis e
/// concluídas; dentro de cada grupo, a ordem do catálogo.
List<MissionView> sortMissions(Iterable<MissionView> missions) {
  const order = {
    MissionStatus.readyToClaim: 0,
    MissionStatus.inProgress: 1,
    MissionStatus.available: 2,
    MissionStatus.completed: 3,
  };
  return [...missions]..sort((a, b) {
    final byStatus = order[a.status]!.compareTo(order[b.status]!);
    return byStatus != 0 ? byStatus : a.sortOrder.compareTo(b.sortOrder);
  });
}

/// Recompensa recebida ao resgatar uma missão.
class MissionClaim {
  const MissionClaim({
    required this.pointsEarned,
    required this.energyEarned,
    required this.totalPoints,
    required this.energy,
    required this.achievements,
  });

  final int pointsEarned;
  final int energyEarned;
  final int totalPoints;
  final double energy;
  final List<UnlockedAchievement> achievements;
}

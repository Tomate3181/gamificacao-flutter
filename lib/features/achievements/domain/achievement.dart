/// Conquista do catálogo, com a data de desbloqueio (se houver).
class Achievement {
  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  final int id;
  final String code;
  final String name;

  /// Condição para desbloquear, mostrada mesmo bloqueada.
  final String description;

  /// Chave do ícone (footprints, leaf, calendar, garden, planet, forest).
  final String icon;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;
}

/// Conquista recém-desbloqueada, devolvida pelas RPCs.
class UnlockedAchievement {
  const UnlockedAchievement({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory UnlockedAchievement.fromJson(Map<String, dynamic> json) {
    return UnlockedAchievement(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }

  final int id;
  final String name;
  final String icon;

  /// Lê a lista `achievements_unlocked` de uma resposta de RPC.
  static List<UnlockedAchievement> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) UnlockedAchievement.fromJson(item),
    ];
  }
}

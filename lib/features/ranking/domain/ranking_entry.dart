/// Linha do ranking global.
class RankingEntry {
  const RankingEntry({
    required this.position,
    required this.nickname,
    required this.totalPoints,
    required this.isMe,
  });

  final int position;
  final String nickname;
  final int totalPoints;
  final bool isMe;
}

/// Ranking pronto para a tela: o top e a linha do jogador logado.
class RankingBoard {
  RankingBoard(List<RankingEntry> rows, {this.limit = 50})
    : top = rows.take(limit).toList(),
      me = rows.where((row) => row.isMe).firstOrNull;

  final int limit;
  final List<RankingEntry> top;
  final RankingEntry? me;

  List<RankingEntry> get podium => top.take(3).toList();
  List<RankingEntry> get rest => top.skip(3).toList();

  /// O jogador está fora do top mostrado.
  bool get meOutsideTop => me != null && !top.any((row) => row.isMe);
}

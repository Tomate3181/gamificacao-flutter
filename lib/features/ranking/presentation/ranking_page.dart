import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/error_retry.dart';
import '../../../widgets/ranking_tile.dart';
import '../domain/ranking_entry.dart';
import 'ranking_controller.dart';

/// Ranking global (`/ranking`), calculado no banco.
class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: rankingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorRetry(
                message:
                    'Não foi possível carregar o ranking. '
                    'Verifique sua conexão e tente de novo.',
                onRetry: () =>
                    ref.read(rankingControllerProvider.notifier).reload(),
              ),
              data: (board) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(rankingControllerProvider.notifier).refresh(),
                child: _RankingList(board: board, textTheme: textTheme),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.board, required this.textTheme});

  final RankingBoard board;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final me = board.me;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ranking',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pontos de missões e planetas concluídos.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                if (me != null) ...[
                  const SizedBox(height: 16),
                  Text('Sua posição', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  RankingTile(
                    position: me.position,
                    nickname: me.nickname,
                    points: me.totalPoints,
                    isMe: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (board.top.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Ninguém pontuou ainda. Seja o primeiro!'),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Top 3', style: textTheme.labelLarge),
            ),
          ),
          _TileList(entries: board.podium, spacing: 10),
          if (board.rest.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text('Demais jogadores', style: textTheme.labelLarge),
              ),
            ),
            _TileList(entries: board.rest, spacing: 8),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ],
    );
  }
}

class _TileList extends StatelessWidget {
  const _TileList({required this.entries, required this.spacing});

  final List<RankingEntry> entries;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: entries.length,
        separatorBuilder: (_, _) => SizedBox(height: spacing),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return RankingTile(
            position: entry.position,
            nickname: entry.nickname,
            points: entry.totalPoints,
            isMe: entry.isMe,
          );
        },
      ),
    );
  }
}

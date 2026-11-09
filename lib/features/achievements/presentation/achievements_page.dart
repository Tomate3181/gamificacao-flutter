import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sprites.dart';
import '../../../widgets/achievement_badge.dart';
import '../../../widgets/error_retry.dart';
import 'achievements_controller.dart';

/// Grade de conquistas (`/achievements`). Bloqueadas aparecem em cinza
/// com a condição visível.
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conquistas'),
        leading: IconButton(
          tooltip: 'Voltar para o perfil',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.profile),
        ),
      ),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorRetry(
          message:
              'Não foi possível carregar as conquistas. '
              'Verifique sua conexão e tente de novo.',
          onRetry: () =>
              ref.read(achievementsControllerProvider.notifier).reload(),
        ),
        data: (achievements) {
          if (achievements.isEmpty) {
            return const Center(child: Text('Nenhuma conquista cadastrada.'));
          }
          final unlocked = achievements.where((a) => a.isUnlocked).length;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '$unlocked de ${achievements.length} desbloqueadas',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return AchievementBadge(
                      name: achievement.name,
                      description: achievement.description,
                      iconAsset: Sprites.achievement(achievement.icon),
                      isUnlocked: achievement.isUnlocked,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

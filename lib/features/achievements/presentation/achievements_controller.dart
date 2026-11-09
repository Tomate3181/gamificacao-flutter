import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_providers.dart';
import '../data/achievement_repository.dart';
import '../domain/achievement.dart';

final achievementsControllerProvider =
    AsyncNotifierProvider<AchievementsController, List<Achievement>>(
      AchievementsController.new,
    );

class AchievementsController extends AsyncNotifier<List<Achievement>> {
  @override
  Future<List<Achievement>> build() async {
    final userId = await requireUserId(ref);
    return ref.read(achievementRepositoryProvider).fetchAll(userId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> refreshSilently() async {
    if (!state.hasValue) return;
    try {
      final userId = await readUserId(ref);
      final list = await ref
          .read(achievementRepositoryProvider)
          .fetchAll(userId);
      if (ref.mounted) state = AsyncData(list);
    } catch (_) {}
  }
}

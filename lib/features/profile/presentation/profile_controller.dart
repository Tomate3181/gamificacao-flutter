import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile_summary.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileSummary>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<ProfileSummary> {
  @override
  Future<ProfileSummary> build() async {
    final userId = await requireUserId(ref);
    return ref.read(profileRepositoryProvider).fetchSummary(userId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> refreshSilently() async {
    if (!state.hasValue) return;
    try {
      final userId = await readUserId(ref);
      final summary = await ref
          .read(profileRepositoryProvider)
          .fetchSummary(userId);
      if (ref.mounted) state = AsyncData(summary);
    } catch (_) {}
  }
}

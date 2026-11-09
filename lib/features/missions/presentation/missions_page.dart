import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/error_retry.dart';
import '../domain/mission.dart';
import 'mission_tile.dart';
import 'missions_controller.dart';

enum _Filter {
  all('Todas'),
  active('Em andamento'),
  available('Disponíveis'),
  completed('Concluídas');

  const _Filter(this.label);

  final String label;

  bool matches(MissionView mission) => switch (this) {
    _Filter.all => true,
    _Filter.active =>
      mission.status == MissionStatus.inProgress ||
          mission.status == MissionStatus.readyToClaim,
    _Filter.available => mission.status == MissionStatus.available,
    _Filter.completed => mission.status == MissionStatus.completed,
  };
}

class MissionsPage extends ConsumerStatefulWidget {
  const MissionsPage({super.key});

  @override
  ConsumerState<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends ConsumerState<MissionsPage> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final missionsAsync = ref.watch(missionsControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: missionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorRetry(
                message:
                    'Não foi possível carregar as missões. '
                    'Verifique sua conexão e tente de novo.',
                onRetry: () =>
                    ref.read(missionsControllerProvider.notifier).reload(),
              ),
              data: (missions) {
                final visible = missions.where(_filter.matches).toList();
                final done = missions
                    .where((m) => m.status == MissionStatus.completed)
                    .length;

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(missionsControllerProvider.notifier)
                      .refreshSilently(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Missões',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$done de ${missions.length} concluídas. '
                                'Inicie uma missão e o progresso conta '
                                'enquanto você joga.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final filter in _Filter.values)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(filter.label),
                                          selected: _filter == filter,
                                          onSelected: (_) =>
                                              setState(() => _filter = filter),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (visible.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _emptyText(_filter),
                                textAlign: TextAlign.center,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          sliver: SliverList.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                MissionTile(mission: visible[index]),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static String _emptyText(_Filter filter) => switch (filter) {
    _Filter.all => 'Nenhuma missão disponível no momento.',
    _Filter.active =>
      'Nenhuma missão em andamento. Inicie uma em "Disponíveis".',
    _Filter.available => 'Você já iniciou todas as missões!',
    _Filter.completed => 'Nenhuma missão concluída ainda. Bora jogar!',
  };
}

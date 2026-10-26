import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../widgets/eco_button.dart';
import '../../../widgets/message_banner.dart';
import '../../../widgets/planet_progress_bar.dart';
import '../../../widgets/planet_view.dart';
import '../../../widgets/resource_counter.dart';
import '../../player/domain/player_stats.dart';
import '../../player/presentation/player_controller.dart';
import '../domain/planet_models.dart';
import 'lumi_controller.dart';
import 'planet_controller.dart';
import 'species_picker_sheet.dart';

/// Home: o planeta atual, com plantio por toque.
class PlanetPage extends ConsumerStatefulWidget {
  const PlanetPage({super.key});

  @override
  ConsumerState<PlanetPage> createState() => _PlanetPageState();
}

class _PlanetPageState extends ConsumerState<PlanetPage> {
  Timer? _growthTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Atualiza o crescimento das mudas uma vez por segundo.
    _growthTicker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _growthTicker?.cancel();
    super.dispose();
  }

  void _tick() {
    final planet = ref.read(planetControllerProvider).value;
    final previous = _now;
    final now = DateTime.now();
    if (planet == null || !planet.hasGrowingTrees(previous)) {
      _now = now;
      return;
    }
    // Alguma muda virou árvore neste segundo? A Lumi comemora.
    final grewUp = planet.trees.values.any(
      (tree) => !tree.isGrown(previous) && tree.isGrown(now),
    );
    if (grewUp) ref.read(lumiControllerProvider.notifier).celebrate();
    setState(() => _now = now);
  }

  Future<void> _onSlotTap(PlanetState planet, int slot) async {
    final messenger = ScaffoldMessenger.of(context);
    final tree = planet.trees[slot];

    if (tree != null) {
      final name = planet.speciesById(tree.speciesId)?.name ?? 'Árvore';
      final text = tree.isGrown(_now)
          ? '$name gerando oxigênio.'
          : '$name crescendo: ${(tree.growth(_now) * 100).floor()}%.';
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
      return;
    }
    if (planet.isCompleted) return;

    ref.read(lumiControllerProvider.notifier).follow(slot);
    final energy = ref.read(playerControllerProvider).value?.energy ?? 0;
    final speciesId = await showSpeciesPicker(
      context,
      species: planet.species,
      energy: energy,
    );
    if (speciesId == null || !mounted) return;

    final outcome = await ref
        .read(planetControllerProvider.notifier)
        .plant(slotIndex: slot, speciesId: speciesId);
    final message =
        outcome.failure?.message ??
        (outcome.planetCompleted
            ? 'Planeta 100% reflorestado! Você ganhou pontos.'
            : null);
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final planetAsync = ref.watch(planetControllerProvider);
    final player = ref.watch(playerControllerProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: planetAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () => ref.read(planetControllerProvider.notifier).reload(),
          ),
          data: (planet) => _PlanetContent(
            planet: planet,
            player: player.value,
            now: _now,
            onSlotTap: (slot) => _onSlotTap(planet, slot),
          ),
        ),
      ),
    );
  }
}

class _PlanetContent extends ConsumerWidget {
  const _PlanetContent({
    required this.planet,
    required this.player,
    required this.now,
    required this.onSlotTap,
  });

  final PlanetState planet;
  final PlayerStats? player;
  final DateTime now;
  final ValueChanged<int> onSlotTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lumi = ref.watch(lumiControllerProvider);
    final plantingSlot = ref.watch(plantingSlotProvider);
    final textTheme = Theme.of(context).textTheme;
    final player = this.player;

    return SingleChildScrollView(
      // Espaço para a barra flutuante.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlanetProgressBar(
                planetName: planet.planet.name,
                reforested: planet.reforestedSlots,
                total: planet.planet.totalSlots,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ResourceCounter(
                      icon: Icons.bolt,
                      label: 'Energia',
                      value: player == null
                          ? '…'
                          : formatResource(player.energy),
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResourceCounter(
                      icon: Icons.air,
                      label: 'Oxigênio',
                      value: player == null
                          ? '…'
                          : formatResource(player.oxygen),
                      color: AppColors.auroraTeal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResourceCounter(
                      icon: Icons.star_rounded,
                      label: 'Pontos',
                      value: player == null ? '…' : '${player.totalPoints}',
                      color: AppColors.hotPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PlanetView(
                totalSlots: planet.planet.totalSlots,
                trees: {
                  for (final entry in planet.trees.entries)
                    entry.key: PlanetSlotTree(
                      speciesId: entry.value.speciesId,
                      growth: entry.value.growth(now),
                    ),
                },
                onSlotTap: onSlotTap,
                lumiMood: lumi.mood,
                lumiTargetSlot: lumi.targetSlot,
                loadingSlot: plantingSlot,
              ),
              const SizedBox(height: 16),
              if (planet.isCompleted)
                const MessageBanner(
                  type: MessageBannerType.info,
                  message:
                      'Planeta concluído! O próximo planeta chega em breve.',
                )
              else
                Text(
                  'Toque numa região poluída para plantar. '
                  'Caminhe para ganhar energia.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MessageBanner(
                message:
                    'Não foi possível carregar o planeta. '
                    'Verifique sua conexão e tente de novo.',
              ),
              const SizedBox(height: 16),
              EcoButton(
                label: 'Tentar de novo',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/planet/presentation/lumi_controller.dart';
import '../../features/player/domain/offline_report.dart';
import '../../features/player/presentation/offline_progress_controller.dart';
import '../../features/player/presentation/player_controller.dart';
import '../../features/steps/presentation/step_controller.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/offline_report_sheet.dart';
import '../utils/number_format.dart';

/// Moldura das telas internas: barra flutuante, pedômetro, coleta de
/// oxigênio enquanto o app está aberto e coleta do tempo fora dele.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const oxygenInterval = Duration(seconds: 10);

  static const items = [
    FloatingNavItem(icon: Icons.public, label: 'Planeta'),
    FloatingNavItem(icon: Icons.flag_outlined, label: 'Missões'),
    FloatingNavItem(icon: Icons.storefront_outlined, label: 'Loja'),
    FloatingNavItem(icon: Icons.leaderboard_outlined, label: 'Ranking'),
    FloatingNavItem(icon: Icons.person_outline, label: 'Perfil'),
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  Timer? _oxygenTimer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onShow: _resume,
      onResume: _resume,
      onHide: _pause,
      onPause: _pause,
    );
    _resume();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _oxygenTimer?.cancel();
    super.dispose();
  }

  /// Fora do app a coleta de 10 em 10 segundos para, para o tempo longe
  /// render pela taxa offline.
  void _pause() {
    _oxygenTimer?.cancel();
    _oxygenTimer = null;
  }

  Future<void> _resume() async {
    if (_oxygenTimer != null) return;
    _oxygenTimer = Timer.periodic(MainShell.oxygenInterval, (_) => _collect());
    await ref.read(offlineProgressControllerProvider.notifier).collect();
  }

  Future<void> _showOfflineReport(OfflineReport report) async {
    final rate = (report.offlineRate * 100).round();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => OfflineReportSheet(
        awayLabel: formatAway(report.away),
        oxygenLabel: '+${formatResource(report.oxygenGained)}',
        rateLabel: 'Fora do app as árvores rendem $rate% do normal.',
        limitNote: report.hitLimit
            ? 'Só as últimas ${formatAway(report.counted)} contaram. '
                  'Melhore o ramo Noite na loja para render por mais tempo.'
            : null,
        onClose: () => sheetContext.pop(),
      ),
    );
    if (mounted) {
      ref.read(offlineProgressControllerProvider.notifier).dismiss();
    }
  }

  Future<void> _collect() async {
    final collected = await ref
        .read(playerControllerProvider.notifier)
        .collectOxygen();
    if (collected > 0 && mounted) {
      ref.read(lumiControllerProvider.notifier).collect();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mantém o pedômetro ligado enquanto o usuário está logado.
    ref.watch(stepControllerProvider);
    ref.listen(offlineProgressControllerProvider, (_, report) {
      if (report != null) {
        ref.read(lumiControllerProvider.notifier).collect();
        _showOfflineReport(report);
      }
    });

    return Scaffold(
      extendBody: true,
      body: widget.shell,
      bottomNavigationBar: FloatingNavBar(
        items: MainShell.items,
        currentIndex: widget.shell.currentIndex,
        onSelected: (index) => widget.shell.goBranch(
          index,
          initialLocation: index == widget.shell.currentIndex,
        ),
      ),
    );
  }
}

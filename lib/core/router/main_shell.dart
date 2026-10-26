import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/planet/presentation/lumi_controller.dart';
import '../../features/player/presentation/player_controller.dart';
import '../../features/steps/presentation/step_controller.dart';
import '../../widgets/floating_nav_bar.dart';

/// Moldura das telas internas: barra flutuante, pedômetro e coleta de
/// oxigênio enquanto o app está aberto.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const oxygenInterval = Duration(seconds: 10);

  static const items = [
    FloatingNavItem(icon: Icons.public, label: 'Planeta'),
    FloatingNavItem(icon: Icons.storefront_outlined, label: 'Loja'),
    FloatingNavItem(icon: Icons.person_outline, label: 'Perfil'),
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  Timer? _oxygenTimer;

  @override
  void initState() {
    super.initState();
    _oxygenTimer = Timer.periodic(MainShell.oxygenInterval, (_) => _collect());
  }

  @override
  void dispose() {
    _oxygenTimer?.cancel();
    super.dispose();
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

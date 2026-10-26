import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'lumi_sprite.dart';
import 'tree_sprite.dart';

/// Árvore desenhada numa região.
class PlanetSlotTree {
  const PlanetSlotTree({required this.speciesId, required this.growth});

  final int speciesId;
  final double growth;
}

/// Superfície do planeta dividida em regiões plantáveis, com a Lumi por cima.
///
/// Regiões sem árvore aparecem poluídas; com árvore, reflorestadas.
class PlanetView extends StatefulWidget {
  const PlanetView({
    super.key,
    required this.totalSlots,
    required this.trees,
    required this.onSlotTap,
    required this.lumiMood,
    this.lumiTargetSlot,
    this.loadingSlot,
    this.columns = 10,
  });

  final int totalSlots;
  final Map<int, PlanetSlotTree> trees;
  final ValueChanged<int> onSlotTap;
  final LumiMood lumiMood;
  final int? lumiTargetSlot;
  final int? loadingSlot;
  final int columns;

  @override
  State<PlanetView> createState() => _PlanetViewState();
}

class _PlanetViewState extends State<PlanetView> {
  static const _wanderEvery = Duration(milliseconds: 2600);

  final _random = math.Random();
  late Timer _wanderTimer;
  Offset _wanderPoint = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    _wanderTimer = Timer.periodic(_wanderEvery, (_) {
      setState(() {
        _wanderPoint = Offset(
          0.1 + _random.nextDouble() * 0.8,
          0.1 + _random.nextDouble() * 0.8,
        );
      });
    });
  }

  @override
  void dispose() {
    _wanderTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = (widget.totalSlots / widget.columns).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tile = constraints.maxWidth / widget.columns;
        final width = tile * widget.columns;
        final height = tile * rows;
        final lumiSize = math.max(tile * 1.2, 36.0);

        final target = widget.lumiTargetSlot;
        final Offset lumiCenter = target != null
            ? Offset(
                (target % widget.columns + 1) * tile,
                (target ~/ widget.columns) * tile + tile * 0.2,
              )
            : Offset(_wanderPoint.dx * width, _wanderPoint.dy * height);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.columns,
                  ),
                  itemCount: widget.totalSlots,
                  itemBuilder: (context, index) => _Slot(
                    index: index,
                    tree: widget.trees[index],
                    isLoading: widget.loadingSlot == index,
                    onTap: () => widget.onSlotTap(index),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: Duration(milliseconds: target != null ? 700 : 2400),
                curve: Curves.easeInOut,
                left: (lumiCenter.dx - lumiSize / 2).clamp(
                  -lumiSize / 4,
                  width - lumiSize * 3 / 4,
                ),
                top: (lumiCenter.dy - lumiSize / 2).clamp(
                  -lumiSize / 2,
                  height - lumiSize / 2,
                ),
                child: IgnorePointer(
                  child: LumiSprite(mood: widget.lumiMood, size: lumiSize),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.index,
    required this.tree,
    required this.isLoading,
    required this.onTap,
  });

  final int index;
  final PlanetSlotTree? tree;
  final bool isLoading;
  final VoidCallback onTap;

  static const _polluted = Color(0xFF5A4A42);
  static const _pollutedAlt = Color(0xFF4E4039);
  static const _soil = Color(0xFF2F7D4A);
  static const _soilAlt = Color(0xFF2A7043);

  @override
  Widget build(BuildContext context) {
    final tree = this.tree;
    final even = (index + index ~/ 10) % 2 == 0;
    final color = tree == null
        ? (even ? _polluted : _pollutedAlt)
        : (even ? _soil : _soilAlt);

    return Semantics(
      button: true,
      label: tree == null
          ? 'Região ${index + 1}, poluída'
          : 'Região ${index + 1}, reflorestada',
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: AppColors.skyDeep.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              if (isLoading) {
                return Padding(
                  padding: EdgeInsets.all(size * 0.25),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                );
              }
              if (tree == null) return const SizedBox.expand();
              return TreeSprite(
                speciesId: tree.speciesId,
                growth: tree.growth,
                size: size,
              );
            },
          ),
        ),
      ),
    );
  }
}

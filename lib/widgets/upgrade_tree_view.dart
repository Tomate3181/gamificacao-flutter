import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Situação visual de um nó.
enum UpgradeTreeNodeState { locked, available, owned, maxed }

/// Nó desenhado na árvore radial.
class UpgradeTreeNode {
  const UpgradeTreeNode({
    required this.id,
    required this.tier,
    required this.angle,
    required this.icon,
    required this.color,
    required this.level,
    required this.maxLevel,
    required this.state,
    required this.semanticLabel,
    this.parentId,
  });

  final int id;
  final int? parentId;

  /// Anel: 1 perto do centro.
  final int tier;

  /// Ângulo em radianos (0 = direita, -pi/2 = topo).
  final double angle;
  final IconData icon;

  /// Cor do ramo.
  final Color color;
  final int level;
  final int maxLevel;
  final UpgradeTreeNodeState state;
  final String semanticLabel;
}

/// Árvore de upgrades em anéis ao redor de um centro. Dá para arrastar e
/// aproximar com pinça. Os nós são ligados ao pai por linhas que acendem
/// quando o filho já foi comprado.
class UpgradeTreeView extends StatefulWidget {
  const UpgradeTreeView({
    super.key,
    required this.nodes,
    required this.center,
    required this.onNodeTap,
    this.selectedId,
    this.tiers = 4,
  });

  final List<UpgradeTreeNode> nodes;

  /// Desenho no meio da árvore.
  final Widget center;
  final ValueChanged<int> onNodeTap;
  final int? selectedId;
  final int tiers;

  static const centerRadius = 38.0;
  static const firstRing = 92.0;
  static const ringSpacing = 70.0;
  static const nodeSize = 48.0;

  static double radiusOf(int tier) => firstRing + (tier - 1) * ringSpacing;

  @override
  State<UpgradeTreeView> createState() => _UpgradeTreeViewState();
}

class _UpgradeTreeViewState extends State<UpgradeTreeView> {
  final _transform = TransformationController();
  Size? _fittedTo;

  double get _canvas =>
      2 * (UpgradeTreeView.radiusOf(widget.tiers) + UpgradeTreeView.nodeSize);

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Enquadra a árvore inteira no espaço disponível.
  void _fit(Size viewport) {
    if (_fittedTo == viewport) return;
    _fittedTo = viewport;
    final scale = math.min(viewport.width, viewport.height) / _canvas;
    final dx = (viewport.width - _canvas * scale) / 2;
    final dy = (viewport.height - _canvas * scale) / 2;
    _transform.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  Offset _position(UpgradeTreeNode node) {
    final radius = UpgradeTreeView.radiusOf(node.tier);
    final middle = _canvas / 2;
    return Offset(
      middle + radius * math.cos(node.angle),
      middle + radius * math.sin(node.angle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positions = {
      for (final node in widget.nodes) node.id: _position(node),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        _fit(constraints.biggest);
        final minScale =
            math.min(constraints.maxWidth, constraints.maxHeight) /
            _canvas *
            0.8;

        return InteractiveViewer(
          transformationController: _transform,
          constrained: false,
          minScale: minScale,
          maxScale: 3,
          boundaryMargin: EdgeInsets.all(_canvas / 2),
          child: SizedBox.square(
            dimension: _canvas,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TreePainter(
                      nodes: widget.nodes,
                      positions: positions,
                      tiers: widget.tiers,
                    ),
                  ),
                ),
                Positioned(
                  left: _canvas / 2 - UpgradeTreeView.centerRadius,
                  top: _canvas / 2 - UpgradeTreeView.centerRadius,
                  child: Container(
                    width: UpgradeTreeView.centerRadius * 2,
                    height: UpgradeTreeView.centerRadius * 2,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.skyMid,
                      border: Border.all(color: AppColors.gold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: widget.center,
                  ),
                ),
                for (final node in widget.nodes)
                  Positioned(
                    left: positions[node.id]!.dx - UpgradeTreeView.nodeSize / 2,
                    top: positions[node.id]!.dy - UpgradeTreeView.nodeSize / 2,
                    child: _NodeButton(
                      node: node,
                      selected: node.id == widget.selectedId,
                      onTap: () => widget.onNodeTap(node.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter({
    required this.nodes,
    required this.positions,
    required this.tiers,
  });

  final List<UpgradeTreeNode> nodes;
  final Map<int, Offset> positions;
  final int tiers;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // Anéis de fundo.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.outline.withValues(alpha: 0.45);
    for (var tier = 1; tier <= tiers; tier++) {
      canvas.drawCircle(center, UpgradeTreeView.radiusOf(tier), ring);
    }

    // Ligações: do centro até a raiz de cada ramo e do pai até o filho.
    for (final node in nodes) {
      final from = node.parentId == null
          ? center
          : positions[node.parentId] ?? center;
      final to = positions[node.id]!;
      final lit =
          node.state == UpgradeTreeNodeState.owned ||
          node.state == UpgradeTreeNodeState.maxed;
      final unlocked = node.state != UpgradeTreeNodeState.locked;
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = lit ? 4 : 2.5
        ..color = lit
            ? node.color
            : unlocked
            ? node.color.withValues(alpha: 0.45)
            : AppColors.outline;
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.nodes != nodes || old.positions != positions || old.tiers != tiers;
}

class _NodeButton extends StatelessWidget {
  const _NodeButton({
    required this.node,
    required this.selected,
    required this.onTap,
  });

  final UpgradeTreeNode node;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = node.state == UpgradeTreeNodeState.locked;
    final maxed = node.state == UpgradeTreeNodeState.maxed;
    final owned = node.state == UpgradeTreeNodeState.owned || maxed;
    final borderColor = locked
        ? AppColors.outline
        : maxed
        ? AppColors.gold
        : node.color;
    const size = UpgradeTreeView.nodeSize;

    return Semantics(
      button: true,
      selected: selected,
      label: node.semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: owned
                      ? Color.alphaBlend(
                          node.color.withValues(alpha: 0.28),
                          AppColors.skyMid,
                        )
                      : AppColors.skyMid,
                  border: Border.all(
                    color: selected ? AppColors.textPrimary : borderColor,
                    width: selected ? 3 : (owned ? 2.5 : 2),
                  ),
                  boxShadow: [
                    if (selected || maxed)
                      BoxShadow(
                        color: (maxed ? AppColors.gold : node.color).withValues(
                          alpha: 0.45,
                        ),
                        blurRadius: 14,
                      ),
                  ],
                ),
                child: Icon(
                  locked ? Icons.lock_outline : node.icon,
                  size: 22,
                  color: locked ? AppColors.textMuted : node.color,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -8,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.skyDeep,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      '${node.level}/${node.maxLevel}',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: maxed ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

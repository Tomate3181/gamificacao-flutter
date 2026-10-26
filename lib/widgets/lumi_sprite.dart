import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Estados da Lumi (seção 10 do GDD).
enum LumiMood { wandering, following, happy, collecting }

/// A guardiã Lumi em pixel art, animada conforme o estado.
///
/// Por enquanto cada estado usa o mesmo quadro com movimentos diferentes;
/// os quadros próprios de cada estado entram depois da validação do estilo.
class LumiSprite extends StatefulWidget {
  const LumiSprite({super.key, required this.mood, this.size = 48});

  final LumiMood mood;
  final double size;

  static const asset = 'assets/sprites/lumi/lumi_idle_0.png';

  @override
  State<LumiSprite> createState() => _LumiSpriteState();
}

class _LumiSpriteState extends State<LumiSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final image = Image.asset(
      LumiSprite.asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      semanticLabel: 'Lumi',
    );

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        child: image,
        builder: (context, child) {
          final t = _controller.value * 2 * math.pi;
          final unit = size / 16;
          var dy = math.sin(t) * unit;
          var scale = 1.0;
          var glow = 0.25;

          switch (widget.mood) {
            case LumiMood.wandering:
              break;
            case LumiMood.following:
              dy = math.sin(t * 2) * unit * 0.6;
            case LumiMood.happy:
              // Pulinhos rápidos.
              dy = -(math.sin(t * 3).abs()) * unit * 4;
              glow = 0.6;
            case LumiMood.collecting:
              scale = 1 + math.sin(t * 2).abs() * 0.08;
              glow = 0.45 + math.sin(t * 2).abs() * 0.35;
          }

          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: glow),
                      blurRadius: size * 0.5,
                      spreadRadius: -size * 0.15,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

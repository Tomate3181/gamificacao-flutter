import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/sprites.dart';
import 'pixel_image.dart';

/// Estados da Lumi (seção 10 do GDD).
enum LumiMood { wandering, following, happy, collecting }

/// A guardiã Lumi em pixel art, com 4 quadros por estado.
class LumiSprite extends StatefulWidget {
  const LumiSprite({super.key, required this.mood, this.size = 48});

  final LumiMood mood;
  final double size;

  @override
  State<LumiSprite> createState() => _LumiSpriteState();
}

class _LumiSpriteState extends State<LumiSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Carrega todos os quadros antes para a animação não piscar.
    for (final mood in LumiMood.values) {
      for (var i = 0; i < Sprites.lumiFrames; i++) {
        precacheImage(AssetImage(Sprites.lumi(mood.name, i)), context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Velocidade da animação por estado (voltas por ciclo de 1,6 s).
  int get _speed => switch (widget.mood) {
    LumiMood.wandering => 1,
    LumiMood.collecting => 2,
    LumiMood.following || LumiMood.happy => 3,
  };

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final frame =
              (t * _speed * Sprites.lumiFrames).floor() % Sprites.lumiFrames;
          // Flutuação suave por cima dos quadros.
          final float = math.sin(t * 2 * math.pi) * size / 32;
          final glow = widget.mood == LumiMood.wandering ? 0.25 : 0.5;

          return Transform.translate(
            offset: Offset(0, float),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: glow),
                    blurRadius: size * 0.5,
                    spreadRadius: -size * 0.18,
                  ),
                ],
              ),
              child: PixelImage(
                Sprites.lumi(widget.mood.name, frame),
                size: size,
                semanticLabel: 'Lumi',
              ),
            ),
          );
        },
      ),
    );
  }
}

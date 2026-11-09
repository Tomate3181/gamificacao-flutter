import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pixel_image.dart';

/// Explosão de partículas em pixel art (folhas, brilhos) por cima do filho.
///
/// Toca uma vez sempre que [trigger] muda. Com "reduzir movimento" ligado
/// no sistema, não anima.
class RewardBurst extends StatefulWidget {
  const RewardBurst({
    super.key,
    required this.trigger,
    required this.particles,
    required this.child,
    this.count = 10,
    this.distance = 48,
    this.particleSize = 14,
    this.duration = const Duration(milliseconds: 900),
  });

  /// Valor que dispara a animação quando muda (ex.: um contador).
  final Object? trigger;

  /// Sprites usados nas partículas.
  final List<String> particles;
  final Widget child;
  final int count;

  /// Até onde as partículas voam, em pixels.
  final double distance;
  final double particleSize;
  final Duration duration;

  @override
  State<RewardBurst> createState() => _RewardBurstState();
}

class _Particle {
  const _Particle(this.angle, this.speed, this.spin, this.asset);

  final double angle;
  final double speed;
  final double spin;
  final String asset;
}

class _RewardBurstState extends State<RewardBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  final _random = math.Random();
  List<_Particle> _particles = const [];

  @override
  void didUpdateWidget(RewardBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger != null) {
      _play();
    }
  }

  void _play() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    if (widget.particles.isEmpty) return;
    _particles = [
      for (var i = 0; i < widget.count; i++)
        _Particle(
          (i / widget.count) * 2 * math.pi + _random.nextDouble() * 0.5,
          0.6 + _random.nextDouble() * 0.4,
          (_random.nextDouble() - 0.5) * 3,
          widget.particles[_random.nextInt(widget.particles.length)],
        ),
    ];
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                if (!_controller.isAnimating || t == 0) {
                  return const SizedBox.shrink();
                }
                final eased = Curves.easeOutCubic.transform(t);
                final half = widget.particleSize / 2;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final center = constraints.biggest.center(Offset.zero);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final p in _particles)
                          Positioned(
                            left:
                                center.dx +
                                math.cos(p.angle) *
                                    widget.distance *
                                    p.speed *
                                    eased -
                                half,
                            // Sobe e depois cai um pouco (gravidade).
                            top:
                                center.dy +
                                math.sin(p.angle) *
                                    widget.distance *
                                    p.speed *
                                    eased +
                                24 * t * t -
                                half,
                            child: Opacity(
                              opacity: (1 - t).clamp(0.0, 1.0),
                              child: Transform.rotate(
                                angle: p.spin * t,
                                child: PixelImage(
                                  p.asset,
                                  size: widget.particleSize,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

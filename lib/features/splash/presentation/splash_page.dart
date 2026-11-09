import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sprites.dart';
import '../../../widgets/pixel_image.dart';

/// Splash: o logo aparece, flutua no céu estrelado e o app segue para
/// /home. Sem sessão, o redirecionamento do GoRouter manda para /login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const duration = Duration(milliseconds: 1800);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  // Flutuar e piscar das estrelas, em loop.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOut,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashPage.duration, () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, _) =>
                  CustomPaint(painter: _StarsPainter(_loop.value)),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(_fade),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _loop,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          0,
                          math.sin(_loop.value * 2 * math.pi) * 6,
                        ),
                        child: child,
                      ),
                      child: const PixelImage(Sprites.logo, size: 168),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'EcoPlanet',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reflorestando planetas esquecidos',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estrelas fixas que piscam em ritmos diferentes.
class _StarsPainter extends CustomPainter {
  _StarsPainter(this.t);

  final double t;

  static final _stars = () {
    final random = math.Random(7);
    return [
      for (var i = 0; i < 40; i++)
        (
          x: random.nextDouble(),
          y: random.nextDouble(),
          phase: random.nextDouble(),
          big: random.nextDouble() > 0.8,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final glow =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin((t + star.phase) * 2 * math.pi));
      final paint = Paint()
        ..color = (star.big ? AppColors.gold : AppColors.textPrimary)
            .withValues(alpha: glow * (star.big ? 0.8 : 0.5));
      final side = star.big ? 3.0 : 2.0;
      canvas.drawRect(
        Rect.fromLTWH(star.x * size.width, star.y * size.height, side, side),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.t != t;
}

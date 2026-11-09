import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Texto que sobe e some por cima do filho, como "+10". Toca sempre que
/// [trigger] muda. Com "reduzir movimento" ligado, só aparece e some.
class FloatingRewardText extends StatefulWidget {
  const FloatingRewardText({
    super.key,
    required this.text,
    required this.trigger,
    required this.child,
    this.color = AppColors.gold,
    this.rise = 28,
  });

  final String? text;
  final Object? trigger;
  final Widget child;
  final Color color;

  /// Quanto o texto sobe, em pixels.
  final double rise;

  @override
  State<FloatingRewardText> createState() => _FloatingRewardTextState();
}

class _FloatingRewardTextState extends State<FloatingRewardText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didUpdateWidget(FloatingRewardText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.text != null) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        Positioned(
          top: -6,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                if (!_controller.isAnimating || widget.text == null) {
                  return const SizedBox.shrink();
                }
                final offset = reduceMotion
                    ? 0.0
                    : -widget.rise * Curves.easeOut.transform(t);
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Opacity(
                    opacity: t < 0.6 ? 1 : (1 - (t - 0.6) / 0.4),
                    child: Text(
                      widget.text!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(color: AppColors.skyDeep, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

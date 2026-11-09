import 'package:flutter/material.dart';

import '../core/theme/sprites.dart';
import 'pixel_image.dart';

/// Árvore numa região do planeta. Enquanto cresce, aparece como muda que
/// vai aumentando até virar a espécie plantada.
class TreeSprite extends StatelessWidget {
  const TreeSprite({
    super.key,
    required this.speciesId,
    required this.growth,
    this.size = 32,
  });

  final int speciesId;

  /// Crescimento de 0 a 1.
  final double growth;
  final double size;

  bool get isGrown => growth >= 1;

  @override
  Widget build(BuildContext context) {
    final scale = isGrown ? 1.0 : 0.6 + growth * 0.4;

    return SizedBox.square(
      dimension: size,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: PixelImage(
            isGrown ? Sprites.tree(speciesId) : Sprites.sprout,
            key: ValueKey(isGrown),
            size: size * scale,
          ),
        ),
      ),
    );
  }
}

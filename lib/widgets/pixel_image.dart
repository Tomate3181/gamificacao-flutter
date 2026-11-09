import 'package:flutter/material.dart';

/// Sprite em pixel art ampliado sem borrar (vizinho mais próximo).
class PixelImage extends StatelessWidget {
  const PixelImage(
    this.asset, {
    super.key,
    required this.size,
    this.semanticLabel,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double size;
  final String? semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox.square(dimension: size),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Árvore numa região do planeta. Enquanto cresce, aparece como muda
/// pequena que vai aumentando.
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

  static String assetFor(int speciesId) =>
      'assets/sprites/trees/tree_$speciesId.png';
  static const sproutAsset = 'assets/sprites/trees/sprout.png';

  bool get isGrown => growth >= 1;

  @override
  Widget build(BuildContext context) {
    final scale = isGrown ? 1.0 : 0.45 + growth * 0.4;

    return SizedBox.square(
      dimension: size,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Image.asset(
          isGrown ? assetFor(speciesId) : sproutAsset,
          width: size * scale,
          height: size * scale,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          // Até os sprites das árvores ficarem prontos.
          errorBuilder: (context, error, stackTrace) => Icon(
            isGrown ? Icons.park : Icons.grass,
            size: size * scale,
            color: isGrown ? AppColors.leafGreen : AppColors.auroraTeal,
          ),
        ),
      ),
    );
  }
}

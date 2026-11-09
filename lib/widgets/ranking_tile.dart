import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/sprites.dart';
import 'pixel_image.dart';

/// Linha do ranking. O top 3 ganha medalha e destaque; o jogador logado
/// ganha borda dourada.
class RankingTile extends StatelessWidget {
  const RankingTile({
    super.key,
    required this.position,
    required this.nickname,
    required this.points,
    this.isMe = false,
  });

  final int position;
  final String nickname;
  final int points;
  final bool isMe;

  static const _medals = {
    1: Color(0xFFFFC94A), // ouro
    2: Color(0xFFC9D3E6), // prata
    3: Color(0xFFE09A6A), // bronze
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final medal = _medals[position];
    final isPodium = medal != null;

    return Semantics(
      label:
          '$positionº lugar: $nickname, $points pontos${isMe ? ', você' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isPodium ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: isPodium ? medal.withValues(alpha: 0.12) : AppColors.skyMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe ? AppColors.gold : (medal ?? AppColors.outline),
            width: isMe || isPodium ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isPodium ? 40 : 32,
              height: isPodium ? 40 : 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medal ?? AppColors.skyDeep,
              ),
              child: Text(
                '$position',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isPodium ? AppColors.skyDeep : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isMe ? '$nickname (você)' : nickname,
                overflow: TextOverflow.ellipsis,
                style: (isPodium ? textTheme.titleMedium : textTheme.bodyLarge)
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const PixelImage(Sprites.points, size: 18),
            const SizedBox(width: 6),
            Text(
              '$points',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/sprites.dart';
import 'lumi_sprite.dart';
import 'pixel_image.dart';

/// Conteúdo do aviso "enquanto você estava fora": a Lumi conta quanto
/// oxigênio as árvores geraram com o app fechado.
class OfflineReportSheet extends StatelessWidget {
  const OfflineReportSheet({
    super.key,
    required this.awayLabel,
    required this.oxygenLabel,
    required this.rateLabel,
    required this.onClose,
    this.limitNote,
  });

  /// Ex.: "2 h 15 min".
  final String awayLabel;

  /// Ex.: "+1.250".
  final String oxygenLabel;

  /// Ex.: "Fora do app as árvores rendem 50%."
  final String rateLabel;

  /// Aviso quando o tempo fora passou do teto (null esconde).
  final String? limitNote;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final limitNote = this.limitNote;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: LumiSprite(mood: LumiMood.collecting, size: 72),
            ),
            const SizedBox(height: 12),
            Text(
              'Enquanto você estava fora',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Você ficou $awayLabel longe. A Lumi cuidou das árvores.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.skyMid,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PixelImage(Sprites.oxygen, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    oxygenLabel,
                    // Fonte padrão: número precisa ser lido sem dúvida.
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('de oxigênio', style: textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              rateLabel,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            if (limitNote != null) ...[
              const SizedBox(height: 4),
              Text(
                limitNote,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.auroraLilac,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: onClose, child: const Text('Coletar')),
          ],
        ),
      ),
    );
  }
}

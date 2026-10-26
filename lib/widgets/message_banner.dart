import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum MessageBannerType { error, info }

/// Faixa de mensagem para erros e avisos dentro de formulários e telas.
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    super.key,
    required this.message,
    this.type = MessageBannerType.error,
  });

  final String message;
  final MessageBannerType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      MessageBannerType.error => AppColors.error,
      MessageBannerType.info => AppColors.auroraTeal,
    };
    final icon = switch (type) {
      MessageBannerType.error => Icons.error_outline,
      MessageBannerType.info => Icons.mark_email_read_outlined,
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sprites.dart';
import '../../../widgets/lumi_sprite.dart';
import '../../../widgets/pixel_image.dart';
import '../../../widgets/reward_burst.dart';
import '../domain/planet_models.dart';

/// Comemoração ao chegar em 100%. Fecha quando o jogador decide viajar.
Future<void> showPlanetCompletedDialog(
  BuildContext context,
  PlanetCompletion completion,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PlanetCompletedDialog(completion: completion),
  );
}

class PlanetCompletedDialog extends StatefulWidget {
  const PlanetCompletedDialog({super.key, required this.completion});

  final PlanetCompletion completion;

  @override
  State<PlanetCompletedDialog> createState() => _PlanetCompletedDialogState();
}

class _PlanetCompletedDialogState extends State<PlanetCompletedDialog> {
  int _burst = 0;

  @override
  void initState() {
    super.initState();
    // Solta as partículas depois que o diálogo aparece.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _burst++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final completion = widget.completion;
    final next = completion.next;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.gold, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: RewardBurst(
                  trigger: _burst == 0 ? null : _burst,
                  particles: const [
                    Sprites.leaf,
                    Sprites.points,
                    Sprites.oxygen,
                  ],
                  count: 16,
                  distance: 90,
                  particleSize: 18,
                  duration: const Duration(milliseconds: 1400),
                  child: const LumiSprite(mood: LumiMood.happy, size: 88),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Planeta salvo!',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${completion.planetName} está 100% reflorestado.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (completion.pointsEarned > 0) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PixelImage(Sprites.points, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '+${completion.pointsEarned} pontos',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              if (next != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.skyMid,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      PixelImage(Sprites.planet(next.theme), size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próximo: planeta ${next.orderIndex}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.auroraTeal,
                              ),
                            ),
                            Text(
                              next.name,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${next.totalSlots} regiões poluídas',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.rocket_launch_outlined),
                label: Text(
                  next == null ? 'Continuar' : 'Seguir viagem',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

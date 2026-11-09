import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/sprites.dart';
import '../../../widgets/error_retry.dart';
import '../../../widgets/progress_card.dart';
import 'profile_controller.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../widgets/eco_button.dart';
import '../../../widgets/message_banner.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../player/presentation/player_controller.dart';
import '../../steps/presentation/step_controller.dart';

/// Perfil: apelido, e-mail, números do jogador, conquistas,
/// configurações (modo demo) e logout.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _simulating = false;

  Future<void> _simulate() async {
    setState(() => _simulating = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(stepControllerProvider.notifier)
        .simulateSteps();
    if (!mounted) return;
    setState(() => _simulating = false);

    final String text;
    if (result.failure != null) {
      text = result.failure!.message;
    } else if (result.accepted == 0) {
      text = 'Limite de passos atingido. Espere um pouco e tente de novo.';
    } else if (result.accepted < result.requested) {
      text =
          '${result.accepted} passos aceitos (limite por tempo). '
          '+${formatResource(result.energyGained)} de energia.';
    } else {
      text =
          '${result.accepted} passos simulados! '
          '+${formatResource(result.energyGained)} de energia.';
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final player = ref.watch(playerControllerProvider).value;
    final steps = ref.watch(stepControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final summary = ref.watch(profileControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    player?.nickname ?? user?.nickname ?? 'Guardião',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  summary.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => ErrorRetry(
                      message: 'Não foi possível carregar seus números.',
                      onRetry: () =>
                          ref.read(profileControllerProvider.notifier).reload(),
                    ),
                    data: (data) => ProgressCard(
                      title: 'Seu progresso',
                      stats: [
                        ProgressStat(
                          iconAsset: Sprites.points,
                          label: 'pontos',
                          value: '${player?.totalPoints ?? 0}',
                        ),
                        ProgressStat(
                          iconAsset: Sprites.boot,
                          label: 'missões',
                          value: '${data.missionsCompleted}',
                        ),
                        ProgressStat(
                          iconAsset: Sprites.leaf,
                          label: 'conquistas',
                          value:
                              '${data.achievementsUnlocked}/${data.achievementsTotal}',
                        ),
                        ProgressStat(
                          iconAsset: Sprites.planet('forest'),
                          label: 'planetas',
                          value: '${data.planetsCompleted}',
                        ),
                        ProgressStat(
                          iconAsset: Sprites.tree(3),
                          label: 'árvores',
                          value: '${data.treesPlanted}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.achievements),
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: const Text('Ver conquistas'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Configurações',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Passos',
                    children: [
                      Text(_sensorText(steps.status)),
                      const SizedBox(height: 4),
                      Text(
                        '${steps.sessionSteps} passos convertidos nesta sessão.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Modo demo',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para testar no emulador, no navegador ou na apresentação. '
                        'Os passos simulados passam pelo mesmo limite do servidor.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      EcoButton(
                        label: 'Simular ${StepController.demoSteps} passos',
                        icon: Icons.directions_walk,
                        isLoading: _simulating,
                        onPressed: _simulate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (auth.authErrorMessage != null) ...[
                    MessageBanner(message: auth.authErrorMessage!),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: auth.isLoading
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da conta'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.outline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _sensorText(StepSensorStatus status) => switch (status) {
    StepSensorStatus.idle ||
    StepSensorStatus.starting => 'Conectando ao pedômetro…',
    StepSensorStatus.active => 'Pedômetro ativo: seus passos viram energia.',
    StepSensorStatus.unsupported =>
      'Este aparelho não tem pedômetro. Use o modo demo abaixo.',
    StepSensorStatus.denied =>
      'Permissão de atividade física negada. Libere nas configurações '
          'do aparelho ou use o modo demo.',
    StepSensorStatus.error =>
      'Não foi possível ler o pedômetro. Use o modo demo abaixo.',
  };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.skyMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

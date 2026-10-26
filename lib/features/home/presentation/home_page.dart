import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/eco_button.dart';
import '../../../widgets/message_banner.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';

/// Home provisória da fase 1: saudação e logout.
/// O planeta, a Lumi e os contadores chegam na fase 2.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final state = ref.watch(authControllerProvider);
    final errorMessage = state.authErrorMessage;
    final textTheme = Theme.of(context).textTheme;

    final name = user?.nickname ?? 'guardião';

    return Scaffold(
      appBar: AppBar(title: const Text('EcoPlanet')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.public,
                    size: 80,
                    color: AppColors.leafGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Olá, $name!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'O planeta e a Lumi chegam na próxima fase.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  if (errorMessage != null) ...[
                    MessageBanner(message: errorMessage),
                    const SizedBox(height: 16),
                  ],
                  EcoButton(
                    label: 'Sair',
                    icon: Icons.logout,
                    isLoading: state.isLoading,
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

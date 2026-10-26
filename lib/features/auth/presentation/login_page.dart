import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/auth_scaffold.dart';
import '../../../widgets/eco_button.dart';
import '../../../widgets/eco_text_field.dart';
import '../../../widgets/message_banner.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.authErrorMessage;

    return AuthScaffold(
      title: 'EcoPlanet',
      subtitle: 'A Lumi está esperando. Entre para continuar reflorestando.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (errorMessage != null) ...[
                MessageBanner(message: errorMessage),
                const SizedBox(height: 16),
              ],
              EcoTextField(
                label: 'E-mail',
                hint: 'voce@exemplo.com',
                controller: _emailController,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              EcoTextField(
                label: 'Senha',
                controller: _passwordController,
                validator: Validators.password,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              EcoButton(
                label: 'Entrar',
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.go(AppRoutes.register),
                child: const Text('Não tem conta? Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

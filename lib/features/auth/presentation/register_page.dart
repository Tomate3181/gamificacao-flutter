import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/auth_scaffold.dart';
import '../../../widgets/eco_button.dart';
import '../../../widgets/eco_text_field.dart';
import '../../../widgets/message_banner.dart';
import '../domain/auth_repository.dart';
import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _confirmationSent = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: _emailController.text,
          password: _passwordController.text,
          nickname: _nicknameController.text,
        );
    // Com sessão aberta, o GoRouter leva para /home sozinho.
    if (result == SignUpResult.confirmationRequired && mounted) {
      setState(() => _confirmationSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.authErrorMessage;

    return AuthScaffold(
      title: 'Criar conta',
      subtitle: 'Escolha um apelido. É ele que aparece no ranking.',
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
              if (_confirmationSent) ...[
                const MessageBanner(
                  type: MessageBannerType.info,
                  message:
                      'Conta criada! Enviamos um link de confirmação para o '
                      'seu e-mail. Confirme e depois entre.',
                ),
                const SizedBox(height: 16),
              ],
              EcoTextField(
                label: 'Apelido',
                hint: 'Ex.: Guardiã Verde',
                controller: _nicknameController,
                validator: Validators.nickname,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.nickname],
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
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
                hint: 'Pelo menos ${Validators.passwordMinLength} caracteres',
                controller: _passwordController,
                validator: Validators.password,
                isPassword: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              EcoTextField(
                label: 'Confirmar senha',
                controller: _confirmController,
                validator: (value) => Validators.passwordConfirmation(
                  value,
                  _passwordController.text,
                ),
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              EcoButton(
                label: 'Criar conta',
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: isLoading ? null : () => context.go(AppRoutes.login),
                child: const Text('Já tem conta? Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

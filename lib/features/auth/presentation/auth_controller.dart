import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_auth_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';

/// Controla o envio dos formulários de login, cadastro e logout.
///
/// O estado é `AsyncLoading` durante a chamada e `AsyncError` com
/// [AuthFailure] quando algo dá errado. A navegação depois do sucesso é
/// feita pelo redirecionamento do GoRouter.
final authControllerProvider =
    NotifierProvider.autoDispose<AuthController, AsyncValue<void>>(
      AuthController.new,
    );

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  /// Retorna o resultado do cadastro, ou `null` se falhou.
  Future<SignUpResult?> signUp({
    required String email,
    required String password,
    required String nickname,
  }) {
    return _run(
      () => _repository.signUp(
        email: email,
        password: password,
        nickname: nickname,
      ),
    );
  }

  Future<void> signOut() => _run(_repository.signOut);

  Future<T?> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final result = await action();
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } on AuthFailure catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

extension AuthErrorMessage on AsyncValue<void> {
  /// Mensagem do erro atual, pronta para a UI.
  String? get authErrorMessage {
    final error = this.error;
    if (error == null) return null;
    return error is AuthFailure
        ? error.message
        : const AuthFailure.unknown().message;
  }
}

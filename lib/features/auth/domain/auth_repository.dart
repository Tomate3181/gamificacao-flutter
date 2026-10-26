import 'app_user.dart';

/// Resultado do cadastro.
enum SignUpResult {
  /// Conta criada e sessão aberta.
  signedIn,

  /// Conta criada, mas o Supabase exige confirmação por e-mail.
  confirmationRequired,
}

/// Contrato de autenticação. A implementação fica em `data/`.
///
/// Os métodos lançam [AuthFailure] em caso de erro.
abstract interface class AuthRepository {
  bool get isSignedIn;

  AppUser? get currentUser;

  /// Emite um evento a cada mudança de sessão.
  Stream<void> authStateChanges();

  /// Emite o id do usuário logado (ou `null`) sempre que ele muda.
  Stream<String?> userIdChanges();

  Future<void> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String nickname,
  });

  Future<void> signOut();
}

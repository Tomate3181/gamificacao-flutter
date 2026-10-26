import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import 'auth_error_mapper.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(Supabase.instance.client.auth),
);

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      nickname: user.userMetadata?['nickname'] as String?,
    );
  }

  @override
  Stream<void> authStateChanges() => _auth.onAuthStateChange.map((_) {});

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _auth.signInWithPassword(email: email.trim(), password: password),
    );
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _guard(
      () => _auth.signUp(
        email: email.trim(),
        password: password,
        // O trigger `handle_new_user` usa esse apelido para criar o perfil.
        data: {'nickname': nickname.trim()},
      ),
    );

    // Com confirmação de e-mail ligada, o Supabase não acusa e-mail repetido:
    // devolve um usuário sem identidades.
    if (response.user?.identities?.isEmpty ?? false) {
      throw const AuthFailure.emailInUse();
    }
    return response.session != null
        ? SignUpResult.signedIn
        : SignUpResult.confirmationRequired;
  }

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure.network();
    }
  }
}

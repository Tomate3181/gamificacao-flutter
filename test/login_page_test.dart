import 'package:ecoplanet/features/auth/data/supabase_auth_repository.dart';
import 'package:ecoplanet/features/auth/domain/app_user.dart';
import 'package:ecoplanet/features/auth/domain/auth_failure.dart';
import 'package:ecoplanet/features/auth/domain/auth_repository.dart';
import 'package:ecoplanet/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  AuthFailure? signInFailure;
  int signInCalls = 0;

  @override
  bool get isSignedIn => false;

  @override
  AppUser? get currentUser => null;

  @override
  Stream<void> authStateChanges() => const Stream.empty();

  @override
  Stream<String?> userIdChanges() => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    if (signInFailure != null) throw signInFailure!;
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async => SignUpResult.signedIn;

  @override
  Future<void> signOut() async {}
}

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  Future<void> pumpLogin(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
  }

  testWidgets('mostra erros de validação e não chama o servidor', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('mostra mensagem clara quando a senha está errada', (
    tester,
  ) async {
    repository.signInFailure = const AuthFailure.invalidCredentials();
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'lumi@eco.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });
}

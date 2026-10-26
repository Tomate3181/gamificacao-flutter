import 'package:ecoplanet/core/router/app_routes.dart';
import 'package:ecoplanet/core/router/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authRedirect', () {
    test('splash nunca redireciona', () {
      expect(
        authRedirect(isSignedIn: false, location: AppRoutes.splash),
        isNull,
      );
      expect(
        authRedirect(isSignedIn: true, location: AppRoutes.splash),
        isNull,
      );
    });

    test('sem sessão, rota interna vai para /login', () {
      expect(
        authRedirect(isSignedIn: false, location: AppRoutes.home),
        AppRoutes.login,
      );
      expect(
        authRedirect(isSignedIn: false, location: '/missions/3'),
        AppRoutes.login,
      );
    });

    test('sem sessão, login e cadastro ficam acessíveis', () {
      expect(
        authRedirect(isSignedIn: false, location: AppRoutes.login),
        isNull,
      );
      expect(
        authRedirect(isSignedIn: false, location: AppRoutes.register),
        isNull,
      );
    });

    test('com sessão, login e cadastro vão para /home', () {
      expect(
        authRedirect(isSignedIn: true, location: AppRoutes.login),
        AppRoutes.home,
      );
      expect(
        authRedirect(isSignedIn: true, location: AppRoutes.register),
        AppRoutes.home,
      );
    });

    test('com sessão, rota interna é liberada', () {
      expect(authRedirect(isSignedIn: true, location: AppRoutes.home), isNull);
    });
  });
}

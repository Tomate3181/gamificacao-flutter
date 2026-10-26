import 'app_routes.dart';

/// Decide para onde mandar o usuário conforme a sessão.
///
/// Retorna `null` quando a rota atual pode ser exibida.
String? authRedirect({required bool isSignedIn, required String location}) {
  // A splash decide sozinha para onde ir depois da animação.
  if (location == AppRoutes.splash) return null;

  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;

  if (!isSignedIn && !isAuthRoute) return AppRoutes.login;
  if (isSignedIn && isAuthRoute) return AppRoutes.home;
  return null;
}

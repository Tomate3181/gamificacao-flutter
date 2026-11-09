/// Caminhos das rotas do app (seção 12 do GDD).
class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const missions = '/missions';
  static const shop = '/shop';
  static const ranking = '/ranking';
  static const profile = '/profile';
  static const achievements = '/achievements';

  static String missionDetails(int id) => '$missions/$id';
}

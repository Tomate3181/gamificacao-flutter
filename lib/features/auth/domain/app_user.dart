/// Usuário autenticado, sem depender de tipos do Supabase.
class AppUser {
  const AppUser({required this.id, required this.email, this.nickname});

  final String id;
  final String email;
  final String? nickname;
}

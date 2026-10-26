/// Erro de autenticação com mensagem pronta para mostrar ao usuário.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  const AuthFailure.invalidCredentials()
    : message = 'E-mail ou senha incorretos.';
  const AuthFailure.emailNotConfirmed()
    : message = 'Confirme seu e-mail antes de entrar.';
  const AuthFailure.emailInUse()
    : message = 'Este e-mail já está cadastrado. Tente entrar.';
  const AuthFailure.weakPassword()
    : message = 'Senha fraca. Use pelo menos 6 caracteres.';
  const AuthFailure.invalidEmail() : message = 'E-mail inválido.';
  const AuthFailure.rateLimited()
    : message = 'Muitas tentativas. Aguarde um pouco e tente de novo.';
  const AuthFailure.network()
    : message = 'Sem conexão com o servidor. Verifique sua internet.';
  const AuthFailure.unknown()
    : message = 'Não foi possível concluir agora. Tente de novo.';

  final String message;

  @override
  String toString() => 'AuthFailure($message)';
}

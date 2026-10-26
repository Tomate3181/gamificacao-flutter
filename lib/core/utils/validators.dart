/// Validações dos formulários. Retornam a mensagem de erro ou `null`.
///
/// As regras do apelido espelham o check da tabela `profiles`.
class Validators {
  const Validators._();

  static const passwordMinLength = 6;
  static const nicknameMinLength = 3;
  static const nicknameMaxLength = 20;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _nicknameRegex = RegExp(r'^[\p{L}\p{N}_ .-]+$', unicode: true);

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe seu e-mail.';
    if (!_emailRegex.hasMatch(text)) return 'E-mail inválido.';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Informe sua senha.';
    if (text.length < passwordMinLength) {
      return 'A senha precisa ter pelo menos $passwordMinLength caracteres.';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Repita a senha.';
    if (value != password) return 'As senhas não são iguais.';
    return null;
  }

  static String? nickname(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escolha um apelido.';
    if (text.length < nicknameMinLength || text.length > nicknameMaxLength) {
      return 'O apelido precisa ter de $nicknameMinLength a '
          '$nicknameMaxLength caracteres.';
    }
    if (!_nicknameRegex.hasMatch(text)) {
      return 'Use só letras, números, espaço, ponto, hífen ou _.';
    }
    return null;
  }
}

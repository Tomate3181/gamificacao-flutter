/// Formata recursos do jogo no padrão brasileiro.
///
/// Até 100 mostra uma casa decimal (12,5); acima disso, inteiro com
/// separador de milhar (1.250).
String formatResource(double value) {
  if (value.abs() < 100) {
    final text = value.toStringAsFixed(1).replaceAll('.', ',');
    return text.endsWith(',0') ? text.substring(0, text.length - 2) : text;
  }
  final digits = value.floor().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1 && digits[i] != '-') {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

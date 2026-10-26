import 'package:ecoplanet/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('aceita e-mail válido', () {
      expect(Validators.email('lumi@ecoplanet.com'), isNull);
      expect(Validators.email('  lumi@ecoplanet.com  '), isNull);
    });

    test('rejeita vazio e formato inválido', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('lumi'), isNotNull);
      expect(Validators.email('lumi@ecoplanet'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('exige pelo menos 6 caracteres', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('confirmação precisa ser igual', () {
      expect(Validators.passwordConfirmation('abcdef', 'abcdef'), isNull);
      expect(Validators.passwordConfirmation('abcdeg', 'abcdef'), isNotNull);
      expect(Validators.passwordConfirmation('', 'abcdef'), isNotNull);
    });
  });

  group('Validators.nickname', () {
    test('aceita apelidos de 3 a 20 caracteres, com acento', () {
      expect(Validators.nickname('Lu'), isNotNull);
      expect(Validators.nickname('Guardiã Verde'), isNull);
      expect(Validators.nickname('a' * 20), isNull);
      expect(Validators.nickname('a' * 21), isNotNull);
    });

    test('rejeita caracteres especiais', () {
      expect(Validators.nickname('lumi<script>'), isNotNull);
      expect(Validators.nickname('lumi@'), isNotNull);
    });
  });
}

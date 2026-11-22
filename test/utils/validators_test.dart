import 'package:flutter_test/flutter_test.dart';

import 'package:capstone1/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('accepts a valid email and rejects malformed addresses', () {
      expect(validateEmail('person@example.com'), isNull);
      expect(validateEmail('person@example'), isNotNull);
      expect(validateEmail('person example@gmail.com'), isNotNull);
    });

    test('allows empty optional email fields', () {
      expect(validateEmail('', required: false), isNull);
    });
  });

  group('validateVietnamesePhone', () {
    test(
      'accepts Vietnamese mobile numbers in local and international form',
      () {
        expect(validateVietnamesePhone('0912345678'), isNull);
        expect(validateVietnamesePhone('+84912345678'), isNull);
        expect(validateVietnamesePhone('091 234 5678'), isNull);
      },
    );

    test('rejects invalid numbers and allows empty optional fields', () {
      expect(validateVietnamesePhone('0123456789'), isNotNull);
      expect(validateVietnamesePhone('123456'), isNotNull);
      expect(validateVietnamesePhone('', required: false), isNull);
    });
  });

  group('validateIdentity', () {
    test(
      'accepts legacy and 12-digit identity numbers and passport format',
      () {
        expect(validateIdentity('123456789'), isNull);
        expect(validateIdentity('012345678901'), isNull);
        expect(validateIdentity('B1234567'), isNull);
      },
    );

    test(
      'rejects invalid identity numbers and allows empty optional fields',
      () {
        expect(validateIdentity('12345678'), isNotNull);
        expect(validateIdentity('ABC'), isNotNull);
        expect(validateIdentity(''), isNull);
      },
    );
  });
}

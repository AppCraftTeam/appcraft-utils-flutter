import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ACRequiredValidation', () {
    const validation = ACRequiredValidation<Object?>();

    test('returns RequiredFieldException for null and empty values', () {
      for (final value in <Object?>[null, '', <int>[], <int>{}]) {
        expect(
          validation.validate(value),
          isA<RequiredFieldException>(),
          reason: '$value',
        );
      }
    });

    test('returns null for filled values of any type', () {
      for (final value in <Object?>[
        'a',
        ' ',
        <int>[1],
        0,
        false
      ]) {
        expect(validation.validate(value), isNull, reason: '$value');
      }
    });
  });

  group('ACMinLengthValidation', () {
    const validation = ACMinLengthValidation(3);

    test('returns MinLengthException with the limit when too short', () {
      for (final value in ['ab', null]) {
        expect(
          validation.validate(value),
          isA<MinLengthException>().having((e) => e.minLength, 'minLength', 3),
          reason: '$value',
        );
      }
    });

    test('returns null when the length reaches the limit', () {
      for (final value in ['abc', 'abcd']) {
        expect(validation.validate(value), isNull, reason: value);
      }
    });
  });

  group('ACMaxLengthValidation', () {
    const validation = ACMaxLengthValidation(3);

    test('returns MaxLengthException with the limit when too long', () {
      expect(
        validation.validate('abcd'),
        isA<MaxLengthException>().having((e) => e.maxLength, 'maxLength', 3),
      );
    });

    test('returns null when the length does not exceed the limit', () {
      for (final value in ['abc', 'ab', null]) {
        expect(validation.validate(value), isNull, reason: '$value');
      }
    });
  });

  group('ACEmailValidation', () {
    const validation = ACEmailValidation();

    test('returns null for valid emails', () {
      const emails = [
        'user@example.com',
        'first.last@sub.example.org',
        '"john doe"@example.com',
        'user@[192.168.0.1]',
      ];

      for (final email in emails) {
        expect(validation.validate(email), isNull, reason: email);
      }
    });

    test('returns WrongEmailException for invalid emails', () {
      const emails = [
        'user.example.com',
        'user@',
        'user@example',
        'user@example.c',
        'us er@example.com',
        '',
        null,
      ];

      for (final email in emails) {
        expect(
          validation.validate(email),
          isA<WrongEmailException>(),
          reason: '$email',
        );
      }
    });

    test('uses emailValidRegExp', () {
      expect(validation.regExp, same(ACEmailValidation.emailValidRegExp));
    });
  });

  group('ACRegExpValidation', () {
    const validation = _DigitsValidation();

    test('returns null when the value matches regExp', () {
      expect(validation.validate('123'), isNull);
    });

    test('returns error when the value does not match or is null', () {
      for (final value in ['12a', '', null]) {
        expect(validation.validate(value), 'digits only', reason: '$value');
      }
    });
  });

  group('ACValidationListExt', () {
    test('returns null for an empty list', () {
      expect(<ACValidation<String, Exception>>[].validate('any'), isNull);
    });

    test('returns the first error in list order', () {
      const validations = <ACValidation<String, Exception>>[
        ACRequiredValidation<String>(),
        ACMinLengthValidation(5),
        ACMaxLengthValidation(1),
      ];

      expect(validations.validate('abc'), isA<MinLengthException>());
    });

    test('returns null when every validation passes', () {
      const validations = <ACValidation<String, Exception>>[
        ACRequiredValidation<String>(),
        ACMaxLengthValidation(5),
      ];

      expect(validations.validate('abc'), isNull);
    });
  });
}

class _DigitsValidation extends ACRegExpValidation<String> {
  const _DigitsValidation();

  @override
  RegExp get regExp => RegExp(r'^\d+$');

  @override
  String get error => 'digits only';
}

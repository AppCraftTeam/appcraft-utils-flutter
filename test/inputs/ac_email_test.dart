import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ACEmail', () {
    test('is empty, pure and optional by default', () {
      const email = ACEmail();

      expect(email.value, '');
      expect(email.isPure, isTrue);
      expect(email.isRequired, isFalse);
    });

    test('is valid for a well-formed email', () {
      const email = ACEmail(value: 'user@example.com', isPure: false);

      expect(email.isValid, isTrue);
      expect(email.displayError, isNull);
    });

    test('returns WrongEmailException for a malformed email', () {
      const email = ACEmail(value: 'user@example', isPure: false);

      expect(email.isValid, isFalse);
      expect(email.displayError, isA<WrongEmailException>());
    });

    test('returns RequiredFieldException for an empty required email', () {
      const email = ACEmail(isRequired: true, isPure: false);

      expect(email.displayError, isA<RequiredFieldException>());
    });

    // NOTE: possible bug, see report
    test('is not valid for an empty optional email', () {
      const email = ACEmail(isPure: false);

      expect(email.isValid, isFalse);
      expect(email.displayError, isA<WrongEmailException>());
    });

    test('copyWith without arguments keeps every field', () {
      const email = ACEmail(value: 'a@b.cd', isPure: false, isRequired: true);

      final copy = email.copyWith();

      expect(copy.value, 'a@b.cd');
      expect(copy.isPure, isFalse);
      expect(copy.isRequired, isTrue);
    });

    test('copyWith replaces each given field', () {
      const email = ACEmail();

      expect(email.copyWith(value: 'a@b.cd').value, 'a@b.cd');
      expect(email.copyWith(isPure: false).isPure, isFalse);
      expect(email.copyWith(isRequired: true).isRequired, isTrue);
    });

    // NOTE: possible bug, see report
    test('is equal to an email that differs only in isRequired', () {
      expect(const ACEmail(), const ACEmail(isRequired: true));
    });
  });
}

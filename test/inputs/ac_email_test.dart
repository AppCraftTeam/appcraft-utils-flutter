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

    test('is valid for an empty optional email', () {
      const email = ACEmail(isPure: false);

      expect(email.isValid, isTrue);
      expect(email.displayError, isNull);
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

    test('is not equal to an email that differs only in isRequired', () {
      expect(const ACEmail(), isNot(const ACEmail(isRequired: true)));
    });

    test('is equal with the same hashCode when fields match', () {
      const email = ACEmail(value: 'a@b.cd', isPure: false, isRequired: true);
      const other = ACEmail(value: 'a@b.cd', isPure: false, isRequired: true);

      expect(email, other);
      expect(email.hashCode, other.hashCode);
    });
  });
}

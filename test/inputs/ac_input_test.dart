import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ACInput', () {
    test('is pure by default', () {
      expect(const _PositiveInput(value: 1).isPure, isTrue);
    });

    test('isValid reflects the validations of the current value', () {
      expect(const _PositiveInput(value: 1).isValid, isTrue);
      expect(const _PositiveInput(value: 0).isValid, isFalse);
    });

    test('displayError hides the error while the input is pure', () {
      expect(const _PositiveInput(value: 0).displayError, isNull);
    });

    test('displayError returns the error once the input is changed', () {
      const valid = _PositiveInput(value: 1, isPure: false);
      const invalid = _PositiveInput(value: 0, isPure: false);

      expect(valid.displayError, isNull);
      expect(invalid.displayError, 'not positive');
    });

    test('validator checks the given value, not the stored one', () {
      const input = _PositiveInput(value: 1);

      expect(input.validator(0), 'not positive');
      expect(input.validator(2), isNull);
    });

    test('is always valid without overridden validations', () {
      const input = _PlainInput(value: -1, isPure: false);

      expect(input.isValid, isTrue);
      expect(input.displayError, isNull);
    });

    test('is equal by value and isPure', () {
      const input = _PositiveInput(value: 1);

      expect(input, const _PositiveInput(value: 1));
      expect(input.hashCode, const _PositiveInput(value: 1).hashCode);
      expect(input, isNot(const _PositiveInput(value: 2)));
      expect(input, isNot(const _PositiveInput(value: 1, isPure: false)));
    });

    test('toString contains value and isPure', () {
      expect(
        const _PositiveInput(value: 1).toString(),
        'ACInput(value: 1, isPure: true)',
      );
    });
  });
}

class _PositiveValidation extends ACValidation<int, String> {
  const _PositiveValidation();

  @override
  String? validate(int? value) => (value ?? 0) > 0 ? null : 'not positive';
}

class _PositiveInput extends ACInput<int, String> {
  const _PositiveInput({required super.value, super.isPure});

  @override
  List<ACValidation<int, String>> validations(int? value) =>
      [const _PositiveValidation()];
}

class _PlainInput extends ACInput<int, String> {
  const _PlainInput({required super.value, super.isPure});
}

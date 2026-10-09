import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

Exception? _errorOf(ACText text) => text.validator(text.value);

void main() {
  group('ACText', () {
    test('accepts any text without limits', () {
      for (final value in ['', 'a', 'a' * 1000]) {
        expect(_errorOf(ACText(value: value)), isNull, reason: value);
      }
    });

    test('requires a value when minLength is set', () {
      expect(
          _errorOf(const ACText(minLength: 3)), isA<RequiredFieldException>());
    });

    test('returns MinLengthException for a too short value', () {
      expect(
        _errorOf(const ACText(value: 'ab', minLength: 3)),
        isA<MinLengthException>().having((e) => e.minLength, 'minLength', 3),
      );
    });

    test('accepts a value of exactly minLength', () {
      expect(_errorOf(const ACText(value: 'abc', minLength: 3)), isNull);
    });

    test('returns MaxLengthException for a too long value', () {
      expect(
        _errorOf(const ACText(value: 'abcd', maxLength: 3)),
        isA<MaxLengthException>().having((e) => e.maxLength, 'maxLength', 3),
      );
    });

    test('accepts a value of exactly maxLength', () {
      expect(_errorOf(const ACText(value: 'abc', maxLength: 3)), isNull);
    });

    test('applies both limits together', () {
      const text = ACText(minLength: 2, maxLength: 4);

      expect(_errorOf(text.copyWith(value: 'a')), isA<MinLengthException>());
      expect(
          _errorOf(text.copyWith(value: 'abcde')), isA<MaxLengthException>());
      expect(_errorOf(text.copyWith(value: 'abc')), isNull);
    });

    test('accepts an empty value when minLength is not positive', () {
      for (final minLength in [0, -1]) {
        expect(_errorOf(ACText(minLength: minLength)), isNull,
            reason: 'minLength: $minLength');
      }
    });

    test('copyWith without arguments keeps every field', () {
      const text =
          ACText(value: 'abc', isPure: false, minLength: 1, maxLength: 5);

      final copy = text.copyWith();

      expect(copy.value, 'abc');
      expect(copy.isPure, isFalse);
      expect(copy.minLength, 1);
      expect(copy.maxLength, 5);
    });

    test('copyWith replaces the given fields', () {
      const text = ACText(minLength: 1, maxLength: 5);

      final copy = text.copyWith(
        value: 'abc',
        isPure: false,
        minLength: const WrappedValue.value(2),
        maxLength: const WrappedValue.value(6),
      );

      expect(copy.value, 'abc');
      expect(copy.isPure, isFalse);
      expect(copy.minLength, 2);
      expect(copy.maxLength, 6);
    });

    test('copyWith resets limits with a wrapped null', () {
      const text = ACText(minLength: 1, maxLength: 5);

      final copy = text.copyWith(
        minLength: const WrappedValue.value(null),
        maxLength: const WrappedValue.value(null),
      );

      expect(copy.minLength, isNull);
      expect(copy.maxLength, isNull);
    });

    test('is not equal to a text that differs only in limits', () {
      const text = ACText(minLength: 1, maxLength: 5);
      const others = {
        'no limits': ACText(),
        'minLength': ACText(minLength: 2, maxLength: 5),
        'maxLength': ACText(minLength: 1, maxLength: 6),
      };

      for (final MapEntry(key: difference, value: other) in others.entries) {
        expect(text, isNot(other), reason: difference);
      }
    });

    test('is equal with the same hashCode when fields match', () {
      const text =
          ACText(value: 'abc', isPure: false, minLength: 1, maxLength: 5);
      const other =
          ACText(value: 'abc', isPure: false, minLength: 1, maxLength: 5);

      expect(text, other);
      expect(text.hashCode, other.hashCode);
    });
  });
}

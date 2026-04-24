// ignore_for_file: prefer_const_constructors
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_search_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('ACSearchStrategy', () {
    group('construction', () {
      test('default constructor sets debounce=300ms and minLength=3', () {
        // Arrange & Act
        final strategy = ACSearchStrategy();

        // Assert
        expect(strategy.debounce, equals(const Duration(milliseconds: 300)));
        expect(strategy.minLength, equals(3));
      });

      test('custom values are stored verbatim', () {
        // Arrange
        const customDebounce = Duration(milliseconds: 750);
        const customMinLength = 5;

        // Act
        final strategy = ACSearchStrategy(
          debounce: customDebounce,
          minLength: customMinLength,
        );

        // Assert
        expect(strategy.debounce, equals(customDebounce));
        expect(strategy.minLength, equals(customMinLength));
      });

      test('Duration.zero debounce is valid (instant trigger)', () {
        // Arrange & Act
        final strategy = ACSearchStrategy(debounce: Duration.zero);

        // Assert
        expect(strategy.debounce, equals(Duration.zero));
        expect(strategy.minLength, equals(3));
      });

      test('minLength == 0 is valid (minimum length check disabled)', () {
        // Arrange & Act
        final strategy = ACSearchStrategy(minLength: 0);

        // Assert
        expect(strategy.minLength, equals(0));
        expect(strategy.debounce, equals(const Duration(milliseconds: 300)));
      });
    });

    group('validation (asserts)', () {
      test('negative debounce triggers assertion failure', () {
        // Arrange & Act & Assert — `Duration(microseconds: -1)` is strictly
        // less than `Duration.zero`, so the const assert must fire.
        expect(
          () => ACSearchStrategy(
            debounce: const Duration(microseconds: -1),
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('negative minLength triggers assertion failure', () {
        // Arrange & Act & Assert
        expect(
          () => ACSearchStrategy(minLength: -1),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('equality (Equatable)', () {
      test('two instances with identical fields are equal', () {
        // Arrange
        final a = ACSearchStrategy(
          debounce: Duration(milliseconds: 500),
          minLength: 2,
        );
        final b = ACSearchStrategy(
          debounce: Duration(milliseconds: 500),
          minLength: 2,
        );

        // Act & Assert
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('two default instances are equal', () {
        // Arrange
        final a = ACSearchStrategy();
        final b = ACSearchStrategy();

        // Act & Assert
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('instances with different debounce are not equal', () {
        // Arrange
        final a = ACSearchStrategy(
          debounce: Duration(milliseconds: 100),
        );
        final b = ACSearchStrategy(
          debounce: Duration(milliseconds: 200),
        );

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('instances with different minLength are not equal', () {
        // Arrange
        final a = ACSearchStrategy(minLength: 2);
        final b = ACSearchStrategy(minLength: 5);

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('instances differing in both fields are not equal', () {
        // Arrange
        final a = ACSearchStrategy(
          debounce: Duration(milliseconds: 100),
          minLength: 2,
        );
        final b = ACSearchStrategy(
          debounce: Duration(milliseconds: 200),
          minLength: 5,
        );

        // Act & Assert
        expect(a, isNot(equals(b)));
      });
    });

    group('props', () {
      test('props covers both debounce and minLength', () {
        // Arrange
        final strategy = ACSearchStrategy(
          debounce: Duration(milliseconds: 450),
          minLength: 4,
        );

        // Act
        final props = List<Object?>.of(strategy.props);

        // Assert — props content is an Equatable implementation detail, but
        // it must at minimum contain both configuration fields so equality
        // reacts to either one changing.
        expect(props, contains(const Duration(milliseconds: 450)));
        expect(props, contains(4));
      });
    });
  });
}

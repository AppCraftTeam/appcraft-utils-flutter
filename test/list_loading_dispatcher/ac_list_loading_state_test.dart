import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_state.dart';
import 'package:test/test.dart';

void main() {
  group('ACListLoadingState', () {
    group('initial()', () {
      test('returns empty items, isLoading=false, hasMore=true, error=null', () {
        // Arrange & Act
        final state = ACListLoadingState<int>.initial();

        // Assert
        expect(state.items, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.hasMore, isTrue);
        expect(state.error, isNull);
      });

      test('is generic and works for any T', () {
        // Arrange & Act
        final intState = ACListLoadingState<int>.initial();
        final stringState = ACListLoadingState<String>.initial();

        // Assert
        expect(intState.items, isA<List<int>>());
        expect(stringState.items, isA<List<String>>());
      });
    });

    group('construction', () {
      test('exposes provided fields', () {
        // Arrange
        const items = <int>[1, 2, 3];
        final error = Exception('boom');

        // Act
        final state = ACListLoadingState<int>(
          items: items,
          isLoading: true,
          hasMore: false,
          error: error,
        );

        // Assert
        expect(state.items, equals(items));
        expect(state.isLoading, isTrue);
        expect(state.hasMore, isFalse);
        expect(state.error, same(error));
      });

      test('defaults error to null when omitted', () {
        // Arrange & Act
        final state = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
        );

        // Assert
        expect(state.error, isNull);
      });
    });

    group('items immutability', () {
      test('items getter returns an unmodifiable list (add throws)', () {
        // Arrange
        final state = ACListLoadingState<int>.initial().copyWith(
          items: <int>[1, 2, 3],
        );

        // Act & Assert
        expect(() => state.items.add(4), throwsUnsupportedError);
      });

      test('items getter returns an unmodifiable list (removeAt throws)', () {
        // Arrange
        final state = ACListLoadingState<int>.initial().copyWith(
          items: <int>[1, 2, 3],
        );

        // Act & Assert
        expect(() => state.items.removeAt(0), throwsUnsupportedError);
      });

      test('items getter returns an unmodifiable list (clear throws)', () {
        // Arrange
        final state = ACListLoadingState<int>.initial().copyWith(
          items: <int>[1, 2, 3],
        );

        // Act & Assert
        expect(state.items.clear, throwsUnsupportedError);
      });
    });

    group('copyWith — no-op', () {
      test('copyWith() with no args returns an equal instance', () {
        // Arrange
        final original = ACListLoadingState<int>(
          items: const <int>[1, 2, 3],
          isLoading: true,
          hasMore: false,
          error: Exception('err'),
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy, equals(original));
      });
    });

    group('copyWith — individual field updates', () {
      test('copyWith(items: ...) updates only items', () {
        // Arrange
        final original = ACListLoadingState<int>.initial();
        const newItems = <int>[10, 20];

        // Act
        final updated = original.copyWith(items: newItems);

        // Assert
        expect(updated.items, equals(newItems));
        expect(updated.isLoading, equals(original.isLoading));
        expect(updated.hasMore, equals(original.hasMore));
        expect(updated.error, equals(original.error));
      });

      test('copyWith(isLoading: ...) updates only isLoading', () {
        // Arrange
        final original = ACListLoadingState<int>.initial();

        // Act
        final updated = original.copyWith(isLoading: true);

        // Assert
        expect(updated.isLoading, isTrue);
        expect(updated.items, equals(original.items));
        expect(updated.hasMore, equals(original.hasMore));
        expect(updated.error, equals(original.error));
      });

      test('copyWith(hasMore: ...) updates only hasMore', () {
        // Arrange
        final original = ACListLoadingState<int>.initial();

        // Act
        final updated = original.copyWith(hasMore: false);

        // Assert
        expect(updated.hasMore, isFalse);
        expect(updated.items, equals(original.items));
        expect(updated.isLoading, equals(original.isLoading));
        expect(updated.error, equals(original.error));
      });

      test('copyWith(error: ...) updates only error', () {
        // Arrange
        final original = ACListLoadingState<int>.initial();
        final newError = Exception('boom');

        // Act
        final updated = original.copyWith(error: newError);

        // Assert
        expect(updated.error, same(newError));
        expect(updated.items, equals(original.items));
        expect(updated.isLoading, equals(original.isLoading));
        expect(updated.hasMore, equals(original.hasMore));
      });
    });

    group('copyWith — error and clearError interaction', () {
      test('default copyWith() keeps existing error untouched', () {
        // Arrange
        final existingError = Exception('existing');
        final original = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
          error: existingError,
        );

        // Act
        final copy = original.copyWith(isLoading: true);

        // Assert
        expect(copy.error, same(existingError));
        expect(copy.isLoading, isTrue);
      });

      test('copyWith(error: newError) replaces the existing error', () {
        // Arrange
        final oldError = Exception('old');
        final newError = Exception('new');
        final original = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
          error: oldError,
        );

        // Act
        final copy = original.copyWith(error: newError);

        // Assert
        expect(copy.error, same(newError));
      });

      test('copyWith(clearError: true) nulls a previously set error', () {
        // Arrange
        final original = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
          error: Exception('boom'),
        );

        // Act
        final copy = original.copyWith(clearError: true);

        // Assert
        expect(copy.error, isNull);
      });

      test('copyWith(clearError: true) wins over error param', () {
        // Arrange
        final original = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
          error: Exception('existing'),
        );

        // Act
        final copy = original.copyWith(
          error: Exception('ignored'),
          clearError: true,
        );

        // Assert
        expect(copy.error, isNull);
      });

      test('copyWith(clearError: true) on no-error state stays null', () {
        // Arrange
        final original = ACListLoadingState<int>.initial();

        // Act
        final copy = original.copyWith(clearError: true);

        // Assert
        expect(copy.error, isNull);
      });
    });

    group('equality', () {
      test('two states with same fields are equal', () {
        // Arrange
        final error = Exception('e');
        final a = ACListLoadingState<int>(
          items: const <int>[1, 2],
          isLoading: true,
          hasMore: false,
          error: error,
        );
        final b = ACListLoadingState<int>(
          items: const <int>[1, 2],
          isLoading: true,
          hasMore: false,
          error: error,
        );

        // Act & Assert
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('states differing in items are not equal', () {
        // Arrange
        final a = ACListLoadingState<int>(
          items: const <int>[1],
          isLoading: false,
          hasMore: true,
        );
        final b = ACListLoadingState<int>(
          items: const <int>[2],
          isLoading: false,
          hasMore: true,
        );

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('states differing in isLoading are not equal', () {
        // Arrange
        final a = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
        );
        final b = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: true,
          hasMore: true,
        );

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('states differing in hasMore are not equal', () {
        // Arrange
        final a = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
        );
        final b = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: false,
        );

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('states differing in error are not equal', () {
        // Arrange
        final a = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
          error: Exception('a'),
        );
        final b = ACListLoadingState<int>(
          items: const <int>[],
          isLoading: false,
          hasMore: true,
          error: Exception('b'),
        );

        // Act & Assert
        expect(a, isNot(equals(b)));
      });
    });
  });
}

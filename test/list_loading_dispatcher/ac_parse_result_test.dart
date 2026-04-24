import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ACParseResult', () {
    group('construction', () {
      test('exposes items and hasMore as provided', () {
        // Arrange
        const items = <int>[1, 2, 3];
        const hasMore = true;

        // Act
        const result = ACParseResult<int>(items: items, hasMore: hasMore);

        // Assert
        expect(result.items, equals(items));
        expect(result.hasMore, isTrue);
      });

      test('accepts an empty items list with hasMore=false', () {
        // Arrange & Act
        const result = ACParseResult<String>(
          items: <String>[],
          hasMore: false,
        );

        // Assert
        expect(result.items, isEmpty);
        expect(result.hasMore, isFalse);
      });

      test('accepts an empty items list with hasMore=true', () {
        // Arrange & Act
        const result = ACParseResult<String>(
          items: <String>[],
          hasMore: true,
        );

        // Assert
        expect(result.items, isEmpty);
        expect(result.hasMore, isTrue);
      });
    });

    group('equality', () {
      test('two instances with same items and hasMore are equal', () {
        // Arrange
        const a = ACParseResult<int>(items: <int>[1, 2, 3], hasMore: true);
        const b = ACParseResult<int>(items: <int>[1, 2, 3], hasMore: true);

        // Act & Assert
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('two empty instances with same hasMore are equal', () {
        // Arrange
        const a = ACParseResult<String>(items: <String>[], hasMore: false);
        const b = ACParseResult<String>(items: <String>[], hasMore: false);

        // Act & Assert
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('instances with different items are not equal', () {
        // Arrange
        const a = ACParseResult<int>(items: <int>[1, 2, 3], hasMore: true);
        const b = ACParseResult<int>(items: <int>[1, 2, 4], hasMore: true);

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('instances with different hasMore are not equal', () {
        // Arrange
        const a = ACParseResult<int>(items: <int>[1, 2, 3], hasMore: true);
        const b = ACParseResult<int>(items: <int>[1, 2, 3], hasMore: false);

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('instances with different items length are not equal', () {
        // Arrange
        const a = ACParseResult<int>(items: <int>[1, 2], hasMore: true);
        const b = ACParseResult<int>(items: <int>[1, 2, 3], hasMore: true);

        // Act & Assert
        expect(a, isNot(equals(b)));
      });
    });

    group('props', () {
      test('props contains items and hasMore', () {
        // Arrange
        const result = ACParseResult<int>(
          items: <int>[10, 20],
          hasMore: false,
        );

        // Act
        final props = result.props;

        // Assert
        expect(props, containsAllInOrder(<Object?>[<int>[10, 20], false]));
      });
    });
  });
}

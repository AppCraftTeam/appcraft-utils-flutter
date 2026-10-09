import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ACEntityMapper', () {
    const mapper = _IntParser();

    test('mapList returns an empty list for null or empty input', () {
      expect(mapper.mapList(null), isEmpty);
      expect(mapper.mapList([]), isEmpty);
    });

    test('mapList drops null and unmappable items keeping the order', () {
      expect(mapper.mapList(['3', null, 'x', '1']), [3, 1]);
    });

    test('mapNotNull returns the mapped value', () {
      expect(mapper.mapNotNull('42'), 42);
    });

    test('mapNotNull throws a parsing error when mapping fails', () {
      for (final input in ['x', null]) {
        expect(
          () => mapper.mapNotNull(input),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              'Exception: Parsing error',
            ),
          ),
          reason: '$input',
        );
      }
    });
  });
}

class _IntParser extends ACEntityMapper<String, int> {
  const _IntParser();

  @override
  int? map(String? input) => int.tryParse(input ?? '');
}

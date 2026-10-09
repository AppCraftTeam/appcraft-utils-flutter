import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

enum _Level { low, mid, high }

void main() {
  group('ACEnumByNameOrNull', () {
    test('returns the value with the given name', () {
      expect(_Level.values.byNameOrNull('mid'), _Level.mid);
    });

    test('returns null for an unknown, empty or null name', () {
      for (final name in ['unknown', '', null]) {
        expect(_Level.values.byNameOrNull(name), isNull, reason: '$name');
      }
    });
  });

  group('ACEnumComparisonOperators', () {
    test('compares values by index', () {
      // Left operand, then expected results of <, <=, >, >= against mid.
      const cases = [
        (_Level.low, true, true, false, false),
        (_Level.mid, false, true, false, true),
        (_Level.high, false, false, true, true),
      ];

      for (final (value, lt, le, gt, ge) in cases) {
        expect(value < _Level.mid, lt, reason: '$value < mid');
        expect(value <= _Level.mid, le, reason: '$value <= mid');
        expect(value > _Level.mid, gt, reason: '$value > mid');
        expect(value >= _Level.mid, ge, reason: '$value >= mid');
      }
    });
  });
}

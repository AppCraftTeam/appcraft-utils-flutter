import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('WrappedValue', () {
    test('resolve returns the fallback when nothing is wrapped', () {
      expect(WrappedValue.resolve<String?>(null, 'fallback'), 'fallback');
    });

    test('resolve returns the wrapped value, including a wrapped null', () {
      expect(
        WrappedValue.resolve<String?>(const WrappedValue.value('new'), 'old'),
        'new',
      );
      expect(
        WrappedValue.resolve<String?>(const WrappedValue.value(null), 'old'),
        isNull,
      );
    });
  });
}

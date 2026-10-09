import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ACInputMixin', () {
    test('isNotValid is the inverse of isValid', () {
      expect(const _Flag(true).isNotValid, isFalse);
      expect(const _Flag(false).isNotValid, isTrue);
    });
  });

  group('ACInputMixinListExt', () {
    test('is valid when every input is valid', () {
      const inputs = <ACInputMixin>[_Flag(true), _Flag(true)];

      expect(inputs.isValid, isTrue);
      expect(inputs.isNotValid, isFalse);
    });

    test('is not valid when one input is not valid', () {
      const inputs = <ACInputMixin>[_Flag(true), _Flag(false)];

      expect(inputs.isValid, isFalse);
      expect(inputs.isNotValid, isTrue);
    });

    test('is valid for an empty list', () {
      const inputs = <ACInputMixin>[];

      expect(inputs.isValid, isTrue);
      expect(inputs.isNotValid, isFalse);
    });
  });
}

class _Flag with ACInputMixin {
  const _Flag(this.isValid);

  @override
  final bool isValid;
}

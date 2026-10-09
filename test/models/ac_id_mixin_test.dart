import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

const _a = _Item('1', 'a');
const _b = _Item('2', 'b');
const _c = _Item('3', 'c');

void main() {
  group('ACIdMixinListExt', () {
    test('setElementByID replaces the element with the same id in place', () {
      const newB = _Item('2', 'new b');
      final items = [_a, _b, _c]..setElementByID(newB);

      expect(items, [_a, newB, _c]);
    });

    test('setElementByID appends an element with a new id', () {
      final items = [_a, _b]..setElementByID(_c);

      expect(items, [_a, _b, _c]);
    });

    test('settedElementByID returns a new list and keeps the source', () {
      const newA = _Item('1', 'new a');
      final items = [_a, _b];

      final result = items.settedElementByID(newA);

      expect(result, [newA, _b]);
      expect(items, [_a, _b]);
    });

    test('removeElementByIDs removes every element with a listed id', () {
      const anotherA = _Item('1', 'another a');
      final items = [_a, _b, anotherA, _c]..removeElementByIDs({'1', '3'});

      expect(items, [_b]);
    });

    test('removeElementByIDs keeps the list for empty or unknown ids', () {
      for (final ids in [
        <String>{},
        {'404'}
      ]) {
        final items = [_a, _b]..removeElementByIDs(ids);

        expect(items, [_a, _b], reason: '$ids');
      }
    });

    test('removedElementByIDs returns a new list and keeps the source', () {
      final items = [_a, _b];

      final result = items.removedElementByIDs({'1'});

      expect(result, [_b]);
      expect(items, [_a, _b]);
    });
  });
}

class _Item with ACIdMixin {
  const _Item(this.id, this.name);

  @override
  final String id;

  final String name;

  @override
  String toString() => '_Item($id, $name)';
}

import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

List<String> _titlesOf(List<ACTitle> items) =>
    [for (final item in items) item.title];

void main() {
  group('TitleMixinListExt', () {
    test('sortedByTitle orders by compareTo, uppercase first', () {
      const items = [
        ACTitle(title: 'b'),
        ACTitle(title: 'a'),
        ACTitle(title: 'C')
      ];

      expect(_titlesOf(items.sortedByTitle()), ['C', 'a', 'b']);
    });

    test('sortedByTitle keeps the source list', () {
      final items = [const ACTitle(title: 'b'), const ACTitle(title: 'a')];

      final sorted = items.sortedByTitle();

      expect(_titlesOf(sorted), ['a', 'b']);
      expect(_titlesOf(items), ['b', 'a']);
    });

    test('sortedByTitle returns an empty list for an empty list', () {
      expect(<ACTitle>[].sortedByTitle(), isEmpty);
    });
  });
}

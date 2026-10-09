import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ACLocalizationManager', () {
    final manager = ACLocalizationManager.instance;

    // The manager is a mutable singleton shared by all tests of this file.
    setUp(() {
      final previousLocale = manager.currentLocale;
      final previousLocalizations = Map.of(manager.localizations);
      addTearDown(() {
        manager.currentLocale = previousLocale;
        manager.localizations
          ..clear()
          ..addAll(previousLocalizations);
      });
    });

    test('instance is a single object', () {
      expect(ACLocalizationManager.instance, same(manager));
    });

    test('defaults to Russian with Russian and English registered', () {
      expect(manager.currentLocale, 'ru');
      expect(manager.localizations.keys, unorderedEquals(['ru', 'en']));
      expect(manager.localization(), isA<ACLocalizationRu>());
    });

    test('returns the localization of the requested locale', () {
      expect(manager.localization('en'), isA<ACLocalizationEn>());
      expect(manager.localization('ru'), isA<ACLocalizationRu>());
    });

    test('returns the localization of the current locale', () {
      manager.currentLocale = 'en';

      expect(manager.localization(), isA<ACLocalizationEn>());
    });

    test('falls back to Russian for an unknown locale', () {
      expect(manager.localization('de'), isA<ACLocalizationRu>());

      manager.currentLocale = 'de';

      expect(manager.localization(), isA<ACLocalizationRu>());
    });

    test('returns a localization registered under a new key', () {
      const custom = _TestLocalization();

      manager.localizations['xx'] = custom;

      expect(manager.localization('xx'), same(custom));
    });
  });
}

class _TestLocalization extends ACLocalizationEn {
  const _TestLocalization();
}

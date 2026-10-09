import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

void main() {
  const ru = ACLocalizationRu();
  const en = ACLocalizationEn();

  // Exception, its Russian text, its English text.
  final cases = <(ACException, String, String)>[
    (const WipException(), ru.wipException, en.wipException),
    (const NotFoundException(), ru.notFoundException, en.notFoundException),
    (
      const RequiredFieldException(),
      ru.requiredFieldException,
      en.requiredFieldException,
    ),
    (
      const MinLengthException(5),
      ru.minLengthException(5),
      en.minLengthException(5),
    ),
    (
      const MaxLengthException(7),
      ru.maxLengthException(7),
      en.maxLengthException(7),
    ),
    (
      const WrongPasswordException(),
      ru.wrongPasswordException,
      en.wrongPasswordException,
    ),
    (
      const WrongLoginException(),
      ru.wrongLoginException,
      en.wrongLoginException,
    ),
    (
      const WrongEmailException(),
      ru.wrongEmailException,
      en.wrongEmailException,
    ),
    (
      const UnauthorizedException(),
      ru.unauthorizedException,
      en.unauthorizedException,
    ),
  ];

  group('ACException', () {
    test('localizedMessage returns the text of the requested locale', () {
      for (final (exception, ruText, enText) in cases) {
        expect(exception.localizedMessage('ru'), ruText);
        expect(exception.localizedMessage('en'), enText);
      }
    });

    test('localizedMessage falls back to Russian for an unknown locale', () {
      for (final (exception, ruText, _) in cases) {
        expect(exception.localizedMessage('de'), ruText);
      }
    });

    test('toString returns the message of the current locale', () {
      final manager = ACLocalizationManager.instance;
      final previousLocale = manager.currentLocale;
      addTearDown(() => manager.currentLocale = previousLocale);

      manager.currentLocale = 'ru';
      final ruMessages = [for (final (e, _, _) in cases) e.toString()];
      manager.currentLocale = 'en';
      final enMessages = [for (final (e, _, _) in cases) e.toString()];

      expect(ruMessages, [for (final (_, ruText, _) in cases) ruText]);
      expect(enMessages, [for (final (_, _, enText) in cases) enText]);
    });
  });

  group('MinLengthException', () {
    test('keeps the length limit', () {
      expect(const MinLengthException(5).minLength, 5);
    });
  });

  group('MaxLengthException', () {
    test('keeps the length limit', () {
      expect(const MaxLengthException(7).maxLength, 7);
    });
  });
}

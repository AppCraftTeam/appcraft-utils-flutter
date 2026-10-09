import 'package:appcraft_utils_flutter/appcraft_utils_flutter.dart';
import 'package:test/test.dart';

/// Every message of [localization], with length limits of 3 and 10.
List<String> _messagesOf(ACLocalization localization) => [
      localization.wipException,
      localization.notFoundException,
      localization.requiredFieldException,
      localization.wrongPasswordException,
      localization.wrongLoginException,
      localization.wrongEmailException,
      localization.unauthorizedException,
      localization.minLengthException(3),
      localization.maxLengthException(10),
    ];

void main() {
  group('ACLocalizationRu', () {
    test('returns Russian messages with the length substituted', () {
      expect(_messagesOf(const ACLocalizationRu()), [
        'В разработке 👨‍💻',
        'Ресурс не найден',
        'Обязательное поле',
        'Некорректный пароль',
        'Некорректный логин',
        'Некорректный E-mail',
        'Требуется авторизация',
        'Минимальная длина 3 символов',
        'Длина превышает 10 символов',
      ]);
    });
  });

  group('ACLocalizationEn', () {
    test('returns English messages with the length substituted', () {
      expect(_messagesOf(const ACLocalizationEn()), [
        'In development 👨‍💻',
        'Resource not found',
        'Required field',
        'Wrong password',
        'Wrong login',
        'Wrong E-mail',
        'Unauthorized',
        'Minimum length 3 characters',
        'Length exceeds 10 characters',
      ]);
    });
  });
}

/// Абстрактный класс для локализации сообщений приложения.
/// Определяет набор обязательных сообщений и методов для конкретной локали.
abstract class ACLocalization {
  /// Создаёт экземпляр локализации.
  const ACLocalization();

  /// Сообщение об ошибке `WipException`.
  String get wipException;

  /// Сообщение об ошибке `NotFoundException`.
  String get notFoundException;

  /// Сообщение об ошибке `RequiredFieldException`.
  String get requiredFieldException;

  /// Сообщение об ошибке `WrongPasswordException`.
  String get wrongPasswordException;

  /// Сообщение об ошибке `WrongLoginException`.
  String get wrongLoginException;

  /// Сообщение об ошибке `WrongEmailException`.
  String get wrongEmailException;

  /// Сообщение об ошибке `UnauthorizedException`.
  String get unauthorizedException;

  /// Сообщение об ошибке `MinLengthException` для указанного [minLength].
  String minLengthException(int minLength);

  /// Сообщение об ошибке `MaxLengthException` для указанного [maxLength].
  String maxLengthException(int maxLength);
}

/// Русская реализация [ACLocalization].
class ACLocalizationRu implements ACLocalization {
  /// Создаёт русскую локализацию.
  const ACLocalizationRu();

  @override
  String get wipException =>
    'В разработке 👨‍💻';

  @override
  String get notFoundException =>
    'Ресурс не найден';

  @override
  String get requiredFieldException =>
    'Обязательное поле';

  @override
  String get wrongPasswordException =>
    'Некорректный пароль';

  @override
  String get wrongLoginException =>
    'Некорректный логин';

  @override
  String get wrongEmailException =>
    'Некорректный E-mail';

  @override
  String get unauthorizedException =>
    'Требуется авторизация';

  @override
  String minLengthException(int minLength) =>
    'Минимальная длина $minLength символов';

  @override
  String maxLengthException(int maxLength) =>
    'Длина превышает $maxLength символов';
}

/// Английская реализация [ACLocalization].
class ACLocalizationEn implements ACLocalization {
  /// Создаёт английскую локализацию.
  const ACLocalizationEn();

  @override
  String get wipException =>
    'In development 👨‍💻';

  @override
  String get notFoundException =>
    'Resource not found';

  @override
  String get requiredFieldException =>
    'Required field';

  @override
  String get wrongPasswordException =>
    'Wrong password';

  @override
  String get wrongLoginException =>
    'Wrong login';

  @override
  String get wrongEmailException =>
    'Wrong E-mail';

  @override
  String get unauthorizedException =>
    'Unauthorized';

  @override
  String minLengthException(int minLength) =>
    'Minimum length $minLength characters';

  @override
  String maxLengthException(int maxLength) =>
    'Length exceeds $maxLength characters';

}

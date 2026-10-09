/// Abstract class for localizing application messages.
///
/// Defines the set of required messages and methods for a specific locale.
abstract class ACLocalization {
  /// Creates a localization instance.
  const ACLocalization();

  /// The `WipException` error message.
  String get wipException;

  /// The `NotFoundException` error message.
  String get notFoundException;

  /// The `RequiredFieldException` error message.
  String get requiredFieldException;

  /// The `WrongPasswordException` error message.
  String get wrongPasswordException;

  /// The `WrongLoginException` error message.
  String get wrongLoginException;

  /// The `WrongEmailException` error message.
  String get wrongEmailException;

  /// The `UnauthorizedException` error message.
  String get unauthorizedException;

  /// Returns the `MinLengthException` error message for the given [minLength].
  String minLengthException(int minLength);

  /// Returns the `MaxLengthException` error message for the given [maxLength].
  String maxLengthException(int maxLength);
}

/// Russian implementation of [ACLocalization].
class ACLocalizationRu implements ACLocalization {
  /// Creates the Russian localization.
  const ACLocalizationRu();

  @override
  String get wipException => 'В разработке 👨‍💻';

  @override
  String get notFoundException => 'Ресурс не найден';

  @override
  String get requiredFieldException => 'Обязательное поле';

  @override
  String get wrongPasswordException => 'Некорректный пароль';

  @override
  String get wrongLoginException => 'Некорректный логин';

  @override
  String get wrongEmailException => 'Некорректный E-mail';

  @override
  String get unauthorizedException => 'Требуется авторизация';

  @override
  String minLengthException(int minLength) =>
      'Минимальная длина $minLength символов';

  @override
  String maxLengthException(int maxLength) =>
      'Длина превышает $maxLength символов';
}

/// English implementation of [ACLocalization].
class ACLocalizationEn implements ACLocalization {
  /// Creates the English localization.
  const ACLocalizationEn();

  @override
  String get wipException => 'In development 👨‍💻';

  @override
  String get notFoundException => 'Resource not found';

  @override
  String get requiredFieldException => 'Required field';

  @override
  String get wrongPasswordException => 'Wrong password';

  @override
  String get wrongLoginException => 'Wrong login';

  @override
  String get wrongEmailException => 'Wrong E-mail';

  @override
  String get unauthorizedException => 'Unauthorized';

  @override
  String minLengthException(int minLength) =>
      'Minimum length $minLength characters';

  @override
  String maxLengthException(int maxLength) =>
      'Length exceeds $maxLength characters';
}

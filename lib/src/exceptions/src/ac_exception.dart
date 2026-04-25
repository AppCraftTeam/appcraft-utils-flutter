import '../../../appcraft_utils_flutter.dart';

final _localization = ACLocalizationManager.instance.localization;

/// Абстрактный класс для пользовательских исключений в приложении.
/// Наследуется от стандартного Exception.
abstract class ACException implements Exception {
  /// Создаёт экземпляр исключения.
  const ACException();

  /// Метод возвращает локализованное сообщение об ошибке.
  /// [localeName] — опциональный параметр для указания конкретной локали.
  String localizedMessage([String? localeName]);

  @override
  String toString() => localizedMessage();
}

/// Исключение для функционала, который еще не реализован (Work In Progress)
class WipException extends ACException {
  /// Создаёт исключение для нереализованного функционала.
  const WipException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).wipException;
}

/// Исключение, когда какой-либо ресурс или элемент не найден
class NotFoundException extends ACException {
  /// Создаёт исключение «ресурс не найден».
  const NotFoundException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).notFoundException;
}

/// Исключение, когда обязательное поле не заполнено
class RequiredFieldException extends ACException {
  /// Создаёт исключение «обязательное поле не заполнено».
  const RequiredFieldException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).requiredFieldException;
}

/// Исключение, когда длина введенного значения меньше минимальной
class MinLengthException extends ACException {
  /// Создаёт исключение с указанным минимально допустимым значением [minLength].
  const MinLengthException(
    this.minLength
  );

  /// Минимально допустимая длина значения.
  final int minLength;

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).minLengthException(minLength);
}

/// Исключение, когда длина введенного значения превышает максимальную
class MaxLengthException extends ACException {
  /// Создаёт исключение с указанным максимально допустимым значением [maxLength].
  const MaxLengthException(
    this.maxLength
  );

  /// Максимально допустимая длина значения.
  final int maxLength;

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).maxLengthException(maxLength);
}

/// Исключение для неверного пароля
class WrongPasswordException extends ACException {
  /// Создаёт исключение «неверный пароль».
  const WrongPasswordException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).wrongPasswordException;
}

/// Исключение для неверного логина
final class WrongLoginException extends ACException {
  /// Создаёт исключение «неверный логин».
  const WrongLoginException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).wrongLoginException;
}

/// Исключение для неверного email
final class WrongEmailException extends ACException {
  /// Создаёт исключение «неверный email».
  const WrongEmailException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).wrongEmailException;
}

/// Исключение для неавторизованных действий
final class UnauthorizedException extends ACException {
  /// Создаёт исключение «неавторизованное действие».
  const UnauthorizedException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).unauthorizedException;
}
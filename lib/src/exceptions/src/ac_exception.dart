import '../../../appcraft_utils_flutter.dart';

final _localization = ACLocalizationManager.instance.localization;

/// Abstract base class for custom application exceptions.
///
/// Inherits from the standard [Exception].
abstract class ACException implements Exception {
  /// Creates an exception instance.
  const ACException();

  /// Returns the localized error message.
  ///
  /// [localeName] is an optional parameter that specifies a particular locale.
  String localizedMessage([String? localeName]);

  @override
  String toString() => localizedMessage();
}

/// Exception for functionality that is not implemented yet (Work In Progress).
class WipException extends ACException {
  /// Creates an exception for not yet implemented functionality.
  const WipException();

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).wipException;
}

/// Exception thrown when a resource or an item is not found.
class NotFoundException extends ACException {
  /// Creates a "resource not found" exception.
  const NotFoundException();

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).notFoundException;
}

/// Exception thrown when a required field is not filled in.
class RequiredFieldException extends ACException {
  /// Creates a "required field is not filled in" exception.
  const RequiredFieldException();

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).requiredFieldException;
}

/// Exception thrown when the entered value is shorter than the minimum length.
class MinLengthException extends ACException {
  /// Creates an exception with the given minimum allowed value [minLength].
  const MinLengthException(this.minLength);

  /// The minimum allowed length of the value.
  final int minLength;

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).minLengthException(minLength);
}

/// Exception thrown when the entered value exceeds the maximum length.
class MaxLengthException extends ACException {
  /// Creates an exception with the given maximum allowed value [maxLength].
  const MaxLengthException(this.maxLength);

  /// The maximum allowed length of the value.
  final int maxLength;

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).maxLengthException(maxLength);
}

/// Exception for a wrong password.
class WrongPasswordException extends ACException {
  /// Creates a "wrong password" exception.
  const WrongPasswordException();

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).wrongPasswordException;
}

/// Exception for a wrong login.
final class WrongLoginException extends ACException {
  /// Creates a "wrong login" exception.
  const WrongLoginException();

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).wrongLoginException;
}

/// Exception for a wrong email.
final class WrongEmailException extends ACException {
  /// Creates a "wrong email" exception.
  const WrongEmailException();

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).wrongEmailException;
}

/// Exception for unauthorized actions.
final class UnauthorizedException extends ACException {
  /// Creates an "unauthorized action" exception.
  const UnauthorizedException();

  @override
  String localizedMessage([String? localeName]) =>
      _localization(localeName).unauthorizedException;
}

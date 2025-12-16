import '../../../appcraft_utils_flutter.dart';

final _localization = ACLocalizationManager.instance.localization;

abstract class ACException implements Exception {
  const ACException();

  String localizedMessage([String? localeName]);

  @override
  String toString() => localizedMessage();
}

class WipException extends ACException {
  const WipException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).wipException;
}

class NotFoundException extends ACException {
  const NotFoundException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).notFoundException;
}

class RequiredFieldException extends ACException {
  const RequiredFieldException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).requiredFieldException;
}

class MinLengthException extends ACException {
  const MinLengthException(
    this.minLength
  );

  final int minLength;

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).minLengthException(minLength);
}

class MaxLengthException extends ACException {
  const MaxLengthException(
    this.maxLength
  );

  final int maxLength;

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).maxLengthException(maxLength);
}

class WrongPasswordException extends ACException {
  const WrongPasswordException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).wrongPasswordException;
}

final class WrongLoginException extends ACException {
  const WrongLoginException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).wrongLoginException;
}

final class WrongEmailException extends ACException {
  const WrongEmailException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).wrongEmailException;
}

final class UnauthorizedException extends ACException {
  const UnauthorizedException();

  @override
  String localizedMessage([String? localeName]) =>
    _localization(localeName).unauthorizedException;
}
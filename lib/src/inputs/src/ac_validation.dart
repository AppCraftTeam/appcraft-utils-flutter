import '../../exceptions/src/ac_exception.dart';

/// Abstract validation class.
///
/// [V] is the type of the value being validated.
/// [E] is the type of the error returned when validation fails.
abstract class ACValidation<V, E> {
  /// Creates a validation.
  const ACValidation();

  /// Validates the value.
  ///
  /// Returns an error object [E] for an invalid value, or null if everything
  /// is fine.
  E? validate(V? value);
}

/// Extension for a list of validators [List<ACValidation>].
///
/// Allows applying several checks to a single value.
extension ACValidationListExt<V, E> on List<ACValidation<V, E>> {
  /// Applies all validations to [value] one by one.
  ///
  /// If one of the validations returns an error, it is returned immediately.
  E? validate(V? value) {
    E? result;

    for (final validation in this) {
      result = validation.validate(value);
      if (result != null) break;
    }

    return result;
  }
}

/// Validation that a value is present.
///
/// Returns [RequiredFieldException] when the value is `null`, an empty
/// `String` or an empty `Iterable`; otherwise returns `null`.
class ACRequiredValidation<T> extends ACValidation<T, Exception> {
  /// Creates a required value validation.
  const ACRequiredValidation();

  @override
  Exception? validate(T? value) {
    if (value == null) return const RequiredFieldException();

    // Additional check for String
    if (value is String && value.isEmpty) return const RequiredFieldException();

    // Additional check for Iterable
    if (value is Iterable && value.isEmpty)
      return const RequiredFieldException();

    return null;
  }
}

/// Validation of the minimum text length.
class ACMinLengthValidation extends ACValidation<String, Exception> {
  /// Creates a minimum length validation for [minLength].
  const ACMinLengthValidation(this.minLength);

  /// The minimum allowed length of the value.
  final int minLength;

  @override
  Exception? validate(String? value) =>
      (value ?? '').length < minLength ? MinLengthException(minLength) : null;
}

/// Validation of the maximum text length.
class ACMaxLengthValidation extends ACValidation<String, Exception> {
  /// Creates a maximum length validation for [maxLength].
  const ACMaxLengthValidation(this.maxLength);

  /// The maximum allowed length of the value.
  final int maxLength;

  @override
  Exception? validate(String? value) =>
      (value ?? '').length > maxLength ? MaxLengthException(maxLength) : null;
}

/// Base abstract regular expression validation.
abstract class ACRegExpValidation<E> extends ACValidation<String, E> {
  /// Creates a regular expression validation.
  const ACRegExpValidation();

  /// The regular expression the value must match.
  RegExp get regExp;

  /// The error returned when the value does not match [regExp].
  E get error;

  @override
  E? validate(String? value) => !regExp.hasMatch(value ?? '') ? error : null;
}

/// Email validation using a regular expression.
class ACEmailValidation extends ACRegExpValidation<Exception> {
  /// Creates an email format validation.
  const ACEmailValidation();

  /// The regular expression for validating an email.
  static final emailValidRegExp = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

  @override
  RegExp get regExp => emailValidRegExp;

  @override
  Exception get error => const WrongEmailException();
}

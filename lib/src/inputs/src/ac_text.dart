import '../../models/src/wrapped_value.dart';
import '../inputs.dart';

/// Class for a text form field.
///
/// Extends [ACInput], where:
/// - `String` is the type of the field value
/// - `Exception` is the type of the validation error
class ACText extends ACInput<String, Exception> {
  /// Creates a text field.
  ///
  /// - [value] is the current text value (an empty string by default)
  /// - [isPure] is a flag indicating whether the value has been changed by
  ///   the user
  /// - [minLength] is the minimum allowed text length
  /// - [maxLength] is the maximum allowed text length
  const ACText(
      {super.value = '', super.isPure, this.minLength, this.maxLength});

  /// The minimum text length (optional).
  final int? minLength;

  /// The maximum text length (optional).
  final int? maxLength;

  /// Overrides [validations] and returns the list of validators that check
  /// that the text is filled in when required and meets the length limits.
  @override
  List<ACValidation<String, Exception>> validations(String? value) {
    final minLength = this.minLength;
    final maxLength = this.maxLength;

    return [
      // If the minimum length is set and greater than zero, add the checks:
      // 1. Required-field check
      // 2. Minimum length check
      // With minLength <= 0 the field is optional and an empty value is valid
      if (minLength != null && minLength > 0) ...[
        const ACRequiredValidation(),
        ACMinLengthValidation(minLength)
      ],

      // If the maximum length is set, add the check
      if (maxLength != null) ACMaxLengthValidation(maxLength)
    ];
  }

  /// Properties used for comparison: [value], [isPure], [minLength] and
  /// [maxLength].
  @override
  List<Object?> get props => [...super.props, minLength, maxLength];

  /// Returns a new instance with the given fields overridden.
  ACText copyWith(
          {String? value,
          bool? isPure,
          WrappedValue<int?>? minLength,
          WrappedValue<int?>? maxLength}) =>
      ACText(
          value: value ?? this.value,
          isPure: isPure ?? this.isPure,
          minLength: WrappedValue.resolve(minLength, this.minLength),
          maxLength: WrappedValue.resolve(maxLength, this.maxLength));
}

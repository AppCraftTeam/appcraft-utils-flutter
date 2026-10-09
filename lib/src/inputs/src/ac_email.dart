import '../../../appcraft_utils_flutter.dart';

/// Class for an email form field.
///
/// Extends [ACInput], where:
/// - `String` is the type of the field value
/// - `Exception` is the type of the validation error
class ACEmail extends ACInput<String, Exception> {
  /// Creates an email field.
  ///
  /// - [value] is the current email value (an empty string by default)
  /// - [isPure] is a flag indicating whether the value has been changed by
  ///   the user
  /// - [isRequired] is a flag indicating whether the field is required
  const ACEmail({super.value = '', super.isPure, this.isRequired = false});

  /// Whether the field is required.
  final bool isRequired;

  /// Overrides [validations] and returns the list of validators for the email.
  @override
  List<ACValidation<String, Exception>> validations(String? value) => [
        // If the field is required, check that it is filled in
        if (isRequired) const ACRequiredValidation(),

        // Check the email format with a regular expression —
        // only for a non-empty value: an empty optional field is valid
        if (value != null && value.isNotEmpty) const ACEmailValidation()
      ];

  /// Properties used for comparison: [value], [isPure] and [isRequired].
  @override
  List<Object?> get props => [...super.props, isRequired];

  /// Returns a new instance with the given fields overridden.
  ACEmail copyWith({String? value, bool? isPure, bool? isRequired}) => ACEmail(
      value: value ?? this.value,
      isPure: isPure ?? this.isPure,
      isRequired: isRequired ?? this.isRequired);
}

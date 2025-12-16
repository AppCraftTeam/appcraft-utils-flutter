import '../../../appcraft_utils_flutter.dart';

class ACEmail extends ACInput<String, Exception> {
  const ACEmail({
    super.value = '',
    super.isPure,
    this.isRequired = false
  });

  final bool isRequired;

  @override
  List<ACValidation<String, Exception>> validations(String? value) =>
    [
      if (isRequired) const ACRequiredValidation(),
      const ACEmailValidation()
    ];

  ACEmail copyWith({
    String? value,
    bool? isPure,
    bool? isRequired
  }) => ACEmail(
    value: value ?? this.value,
    isPure: isPure ?? this.isPure,
    isRequired: isRequired ?? this.isRequired
  );

}
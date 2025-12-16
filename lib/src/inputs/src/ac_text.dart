import '../../models/src/wrapped_value.dart';
import '../inputs.dart';

class ACText extends ACInput<String, Exception> {
  const ACText({
    super.value = '',
    super.isPure,
    this.minLength,
    this.maxLength
  });

  final int? minLength;
  final int? maxLength;

  @override
  List<ACValidation<String, Exception>> validations(String? value) => [
    if (minLength != null)...[
      const ACRequiredValidation(),
      ACMinLengthValidation(minLength ?? 0)
    ],

    if (maxLength != null)
      ACMaxLengthValidation(maxLength ?? 0)
  ];

  ACText copyWith({
    String? value,
    bool? isPure,
    WrappedValue<int?>? minLength,
    WrappedValue<int?>? maxLength
  }) => ACText(
    value: value ?? this.value,
    isPure: isPure ?? this.isPure,
    minLength: WrappedValue.resolve(minLength, this.minLength),
    maxLength: WrappedValue.resolve(maxLength, this.maxLength)
  );
}
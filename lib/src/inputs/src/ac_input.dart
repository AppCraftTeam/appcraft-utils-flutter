import 'package:equatable/equatable.dart';

import '../../../appcraft_utils_flutter.dart';

abstract class ACInput<V, E> with ACInputMixin, EquatableMixin {
  const ACInput({
    required this.value,
    this.isPure = true
  });

  final V value;

  // Значение не менялось
  final bool isPure;

  bool get isValid => validator(value) == null;

  bool get isNotValid => !isValid;

  // Если значение не менялось, то ошибка не возвращается
  E? get displayError => isPure ?
    null :
    validator(value);

  E? validator(V? value) => 
    validations(value)
    .validate(value);

  List<ACValidation<V, E>> validations(V? value) => [];

  @override
  String toString() => 'FormInput(value: $value, isPure: $isPure)';

  @override
  List<Object?> get props => [
    value,
    isPure
  ];
}
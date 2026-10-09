import 'package:equatable/equatable.dart';

import '../../../appcraft_utils_flutter.dart';

/// Abstract class for handling form input.
///
/// [V] is the type of the field value.
/// [E] is the type of the validation error.
abstract class ACInput<V, E> with ACInputMixin, Equatable {
  /// Creates an input.
  ///
  /// [value] is the current field value.
  /// [isPure] is a flag indicating whether the value has been changed by the
  /// user.
  const ACInput({required this.value, this.isPure = true});

  /// The current field value.
  final V value;

  /// Whether the value has not been changed by the user.
  ///
  /// `true` — the value has not been changed,
  /// `false` — it has been changed.
  final bool isPure;

  /// Whether the field is valid: true if there are no errors.
  bool get isValid => validator(value) == null;

  /// The error to display.
  ///
  /// If the value has not been changed (isPure == true), no errors are shown.
  E? get displayError => isPure ? null : validator(value);

  /// Validates the value.
  E? validator(V? value) => validations(value).validate(value);

  /// The list of validations for the field.
  ///
  /// Empty by default; overridden in concrete implementations.
  List<ACValidation<V, E>> validations(V? value) => [];

  @override
  String toString() => 'ACInput(value: $value, isPure: $isPure)';

  @override
  List<Object?> get props => [value, isPure];
}

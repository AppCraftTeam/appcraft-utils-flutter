/// Mixin for form input.
///
/// Adds properties for checking whether a field is valid.
mixin ACInputMixin {
  /// Whether the field is valid.
  ///
  /// Must be implemented by the class that uses the mixin.
  bool get isValid;

  /// Whether the field is invalid.
  ///
  /// The inverse of [isValid].
  bool get isNotValid => !isValid;
}

/// Extension for a list of objects with the [ACInputMixin] mixin.
extension ACInputMixinListExt on List<ACInputMixin> {
  /// Whether all fields in the list are valid.
  bool get isValid => every((e) => e.isValid);

  /// Whether at least one field is invalid.
  ///
  /// The inverse of [isValid].
  bool get isNotValid => !isValid;
}

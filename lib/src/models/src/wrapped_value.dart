/// Wrapper class for a value of type [T].
///
/// Used to state explicitly that a value is passed as a "wrapper" rather than
/// directly, which is handy for `copyWith` methods and immutable objects.
class WrappedValue<T> {
  /// Creates a wrapper with the given value.
  const WrappedValue.value(this.value);

  /// The stored value.
  final T value;

  /// Safely extracts the value from a [WrappedValue].
  ///
  /// If [wrappedValue] is null, returns [anotherValue].
  /// Otherwise returns the value from the wrapper.
  static T resolve<T>(WrappedValue<T>? wrappedValue, T anotherValue) =>
      wrappedValue == null ? anotherValue : wrappedValue.value;
}

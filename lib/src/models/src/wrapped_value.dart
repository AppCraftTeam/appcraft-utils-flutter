class WrappedValue<T> {
  const WrappedValue.value(this.value);

  final T value;

  static T resolve<T>(
    WrappedValue<T>? wrappedValue,
    T anotherValue
  ) => wrappedValue == null ?
    anotherValue :
    wrappedValue.value;
}
/// Base abstract entity mapper.
///
/// Converts a value of type [Input] into a value of type [Output].
abstract class ACEntityMapper<Input, Output> {
  /// Creates a mapper instance.
  const ACEntityMapper();

  /// Converts [input] into [Output], or returns `null`
  /// if the conversion is not possible.
  Output? map(Input? input);

  /// Converts the list [inputs], dropping the elements for which
  /// [map] returned `null`.
  ///
  /// Returns an empty list if [inputs] is `null`.
  List<Output> mapList(List<Input?>? inputs) =>
      inputs?.map(map).whereType<Output>().toList() ?? [];

  /// Converts [input] into [Output].
  ///
  /// Throws an [Exception] if the result is `null`.
  Output mapNotNull(Input? input) {
    final output = map(input);

    if (output == null) throw Exception('Parsing error');
    return output;
  }
}

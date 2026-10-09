/// Extension for safely looking up an enum value by name.
extension ACEnumByNameOrNull<T extends Enum> on Iterable<T> {
  /// Returns the enum value for [name], or `null` if there is no match
  /// or [name] is `null`.
  T? byNameOrNull(String? name) {
    try {
      return byName(name ?? '');
    } on Object catch (_) {
      return null;
    }
  }
}

/// Extension that adds [Enum.index]-based comparison operators to enum
/// values.
extension ACEnumComparisonOperators<T extends Enum> on T {
  /// Returns `true` if the index of this value is less than the index of
  /// [other].
  bool operator <(T other) => index < other.index;

  /// Returns `true` if the index of this value is less than or equal to the
  /// index of [other].
  bool operator <=(T other) => index <= other.index;

  /// Returns `true` if the index of this value is greater than the index of
  /// [other].
  bool operator >(T other) => index > other.index;

  /// Returns `true` if the index of this value is greater than or equal to the
  /// index of [other].
  bool operator >=(T other) => index >= other.index;
}

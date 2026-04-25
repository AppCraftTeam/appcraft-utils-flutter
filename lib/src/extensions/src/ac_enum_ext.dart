/// Расширение для безопасного поиска значения enum по имени.
extension ACEnumByNameOrNull<T extends Enum> on Iterable<T> {

  /// Возвращает значение enum по [name] или `null`, если совпадение не найдено
  /// либо [name] равен `null`.
  T? byNameOrNull(String? name) {
    try {
      return byName(name ?? '');
    } on Object catch (_) {
      return null;
    }
  }

}

/// Расширение, добавляющее enum-значениям операторы сравнения по [Enum.index].
extension ACEnumComparisonOperators<T extends Enum> on T {
  /// Возвращает `true`, если индекс текущего значения меньше индекса [other].
  bool operator <(T other) => index < other.index;

  /// Возвращает `true`, если индекс текущего значения меньше или равен индексу [other].
  bool operator <=(T other) => index <= other.index;

  /// Возвращает `true`, если индекс текущего значения больше индекса [other].
  bool operator >(T other) => index > other.index;

  /// Возвращает `true`, если индекс текущего значения больше или равен индексу [other].
  bool operator >=(T other) => index >= other.index;
}

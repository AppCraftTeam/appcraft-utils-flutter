/// Базовый абстрактный маппер сущностей.
///
/// Преобразует значение типа [Input] в значение типа [Output].
abstract class ACEntityMapper<Input, Output> {
  /// Создаёт экземпляр маппера.
  const ACEntityMapper();

  /// Преобразует [input] в [Output] либо возвращает `null`,
  /// если преобразование невозможно.
  Output? map(Input? input);

  /// Преобразует список [inputs], отбрасывая элементы, для которых
  /// [map] вернул `null`. Возвращает пустой список, если [inputs] равен `null`.
  List<Output> mapList(List<Input?>? inputs) =>
    inputs?.map(map).whereType<Output>().toList() ?? [];

  /// Преобразует [input] в [Output]. Бросает [Exception], если результат `null`.
  Output mapNotNull(Input? input) {
    final output = map(input);

    if (output == null) throw Exception('Parsing error');
    return output;
  }
}

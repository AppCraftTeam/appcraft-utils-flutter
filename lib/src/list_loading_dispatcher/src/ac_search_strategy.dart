import 'package:equatable/equatable.dart';

/// Конфигурация поискового поведения диспатчера.
///
/// Передаётся в конструктор `ACListLoadingDispatcher` и управляет:
/// - задержкой [debounce] перед фактическим запросом при изменившемся query;
/// - минимальной длиной [minLength], при которой поиск активируется.
///
/// Применяется только в `reload`. В `loadMore` поиск игнорируется (см.
/// описание методов диспатчера).
class ACSearchStrategy extends Equatable {
  /// Создаёт стратегию с заданными [debounce] и [minLength].
  ///
  /// Оба параметра должны быть неотрицательными. `Duration.zero` у
  /// [debounce] означает «без задержки»; `minLength == 0` — «минимум не
  /// применяется, поиск активируется при любом непустом query».
  ///
  /// Оба ограничения проверяются рантайм-ассертами (конструктор не `const`,
  /// чтобы сравнение `Duration.inMicroseconds` было допустимо).
  ACSearchStrategy({
    this.debounce = const Duration(milliseconds: 300),
    this.minLength = 3,
  })  : assert(
          debounce.inMicroseconds >= 0,
          'debounce must be non-negative',
        ),
        assert(minLength >= 0, 'minLength must be non-negative');

  /// Задержка перед стартом загрузки при изменившемся query.
  final Duration debounce;

  /// Минимальная длина query для активации поиска.
  final int minLength;

  @override
  List<Object?> get props => [
        debounce,
        minLength,
      ];
}

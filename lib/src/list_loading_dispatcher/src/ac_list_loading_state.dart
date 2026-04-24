import 'package:equatable/equatable.dart';

/// Immutable снапшот состояния диспатчера загрузки списков.
///
/// Публикуется через `ACNotifier` и дублируется геттерами диспатчера. Все
/// поля формируются самим диспатчером; внешняя мутация не предусмотрена.
///
/// Поле [items] гарантированно неизменяемо: конструктор оборачивает
/// переданный список в `List.unmodifiable`, поэтому попытка мутировать
/// возвращённый `items` всегда вызывает `UnsupportedError`.
class ACListLoadingState<T> extends Equatable {
  /// Создаёт снапшот с произвольными значениями полей.
  ///
  /// Вызывающий код отвечает за согласованность полей. Для типовых
  /// переходов предпочтительнее использовать [copyWith] или фабрику
  /// [ACListLoadingState.initial].
  ACListLoadingState({
    required List<T> items,
    required this.isLoading,
    required this.hasMore,
    this.error,
  }) : items = List<T>.unmodifiable(items);

  /// Пустое начальное состояние.
  ///
  /// `items = []`, `isLoading = false`, `hasMore = true`, `error = null`.
  /// Используется диспатчером при инициализации и может использоваться
  /// потребителем как безопасное значение по умолчанию.
  factory ACListLoadingState.initial() => ACListLoadingState<T>(
    items: const [],
    isLoading: false,
    hasMore: true,
  );

  /// Накопленные элементы списка.
  ///
  /// Всегда неизменяемый список: попытки `add`, `removeAt`, `clear` и
  /// аналогичные мутации вызывают `UnsupportedError`.
  final List<T> items;

  /// Идёт ли сейчас загрузка (включая ожидание debounce-таймера).
  final bool isLoading;

  /// Есть ли ещё элементы для догрузки через `loadMore`.
  final bool hasMore;

  /// Последняя зафиксированная ошибка загрузки или `null`.
  ///
  /// Сохраняется до следующего успешного старта новой загрузки.
  final Object? error;

  /// Чистое функциональное обновление снапшота.
  ///
  /// Параметры, не переданные явно, сохраняют текущее значение. Чтобы
  /// сбросить [error] в `null`, передайте `clearError: true` — передача
  /// `error: null` воспринимается как «значение не меняется», потому что
  /// тип поля — `Object?`.
  ACListLoadingState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) => ACListLoadingState<T>(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [items, isLoading, hasMore, error];
}

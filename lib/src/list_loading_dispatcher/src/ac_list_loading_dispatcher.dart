import '../../notifier/notifier.dart';
import 'ac_cancel_strategy.dart';
import 'ac_list_loading_params.dart';
import 'ac_list_loading_parser.dart';
import 'ac_list_loading_state.dart';

/// Диспатчер загрузки списков с пагинацией.
///
/// Инкапсулирует жизненный цикл загрузок: `reload` перезапускает список с
/// нуля, `loadMore` догружает следующую страницу, `cancel` снимает активную
/// загрузку без сброса накопленных элементов, `dispose` освобождает ресурсы.
///
/// Состояние публикуется двумя способами:
/// - через геттеры [items], [isLoading], [hasMore], [error] — для прямого
///   доступа из Cubit/виджета;
/// - через [notifier] — потоком снапшотов [ACListLoadingState], на который
///   можно подписаться (`resendLastEvent: true` гарантирует, что поздние
///   подписчики получат последний снапшот).
///
/// Тип [T] — элемент списка. Тип [R] — ответ loader'а; преобразуется в
/// [ACParseResult] переданным [parser]. Диспатчер не делает предположений
/// о форме [R]: поддерживаются и offset-, и cursor-пагинация (контекст
/// хранится на стороне потребителя через замыкание).
///
/// На этапе User Story 1 поиск и per-call override стратегии отмены ещё не
/// поддерживаются: [ACListLoadingParamsMixin.query] в этой фазе игнорируется.
final class ACListLoadingDispatcher<T, R> {
  /// Создаёт диспатчер с заданным [parser].
  ///
  /// [parser] вызывается диспатчером синхронно над уже дождавшимся ответом
  /// loader'а. Если парсер бросает исключение — оно перехватывается и
  /// уходит в [error] как ошибка загрузки.
  ACListLoadingDispatcher({
    required this.parser,
  }) {
    _emit();
  }

  /// Парсер, преобразующий ответ loader'а в [ACParseResult].
  ///
  /// Задаётся один раз при создании диспатчера и далее не меняется.
  final ACListLoadingParser<T, R> parser;

  final List<T> _items = <T>[];
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  bool _disposed = false;
  ACCancelStrategy? _activeCancel;

  final ACNotifier<ACListLoadingState<T>> _notifier =
      _ResendingNotifier<ACListLoadingState<T>>();

  /// Неизменяемый список накопленных элементов.
  ///
  /// Возвращается через `List.unmodifiable` — попытка мутировать снаружи
  /// вызывает `UnsupportedError`.
  List<T> get items => List<T>.unmodifiable(_items);

  /// Идёт ли сейчас загрузка.
  bool get isLoading => _isLoading;

  /// Есть ли ещё элементы для догрузки через [loadMore].
  bool get hasMore => _hasMore;

  /// Последняя зафиксированная ошибка загрузки или `null`.
  ///
  /// Очищается при старте нового [reload]/[loadMore]; сохраняется между
  /// вызовами, пока не стартует очередная успешная загрузка.
  Object? get error => _error;

  /// Наблюдаемый канал снапшотов состояния.
  ///
  /// Возвращает один и тот же экземпляр [ACNotifier] на всё время жизни
  /// диспатчера. Подписчик получает [ACListLoadingState] при каждом
  /// изменении состояния; поздние подписчики получают последний снапшот
  /// благодаря `resendLastEvent: true`.
  ACNotifier<ACListLoadingState<T>> get notifier => _notifier;

  /// Перезагрузить список.
  ///
  /// Отменяет активную загрузку (если есть), выставляет `isLoading = true`,
  /// сбрасывает [error] и вызывает [load] с переданными [params]. Результат
  /// прогоняется через [parser]; элементы из [ACParseResult.items]
  /// **заменяют** текущее содержимое списка, [hasMore] обновляется.
  ///
  /// Исключения loader'а и парсера перехватываются и попадают в [error];
  /// `isLoading` сбрасывается в `false`, элементы не меняются.
  ///
  /// Результат, пришедший после [dispose] или после того, как успели
  /// запустить более новый [reload], игнорируется — снапшот не отправляется
  /// и внутренние поля не мутируются.
  Future<void> reload<P extends ACListLoadingParamsMixin>({
    required P params,
    required Future<R> Function(P params) load,
  }) async {
    if (_disposed) return;

    final previousCancel = _activeCancel;
    final capturedCancel = ACOperationCancelStrategy();
    _activeCancel = capturedCancel;
    _isLoading = true;
    _error = null;
    _emit();

    if (previousCancel != null) {
      await previousCancel.cancel();
    }
    if (_disposed) return;
    if (!identical(_activeCancel, capturedCancel)) return;

    R? response;
    try {
      response = await capturedCancel.run<R>(load(params));
    } on Object catch (error) {
      if (_disposed) return;
      if (!identical(_activeCancel, capturedCancel)) return;
      _error = error;
      _isLoading = false;
      _emit();
      return;
    }

    if (_disposed) return;
    if (!identical(_activeCancel, capturedCancel)) return;
    if (response == null) return;

    final ACParseResult<T> parsed;
    try {
      parsed = parser(response);
    } on Object catch (error) {
      if (_disposed) return;
      if (!identical(_activeCancel, capturedCancel)) return;
      _error = error;
      _isLoading = false;
      _emit();
      return;
    }

    if (_disposed) return;
    if (!identical(_activeCancel, capturedCancel)) return;

    _items
      ..clear()
      ..addAll(parsed.items);
    _hasMore = parsed.hasMore;
    _isLoading = false;
    _emit();
  }

  /// Догрузить следующую страницу.
  ///
  /// Игнорируется (без ошибки, без изменения состояния), если:
  /// - уже идёт другая загрузка (`isLoading == true`);
  /// - [hasMore] == `false`;
  /// - диспатчер уже `dispose`-нут.
  ///
  /// В остальных случаях ведёт себя аналогично [reload], но элементы из
  /// [ACParseResult.items] **добавляются** в конец существующего списка.
  Future<void> loadMore<P extends ACListLoadingParamsMixin>({
    required P params,
    required Future<R> Function(P params) load,
  }) async {
    if (_disposed) return;
    if (_isLoading) return;
    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    _emit();

    final capturedCancel = ACOperationCancelStrategy();
    _activeCancel = capturedCancel;

    R? response;
    try {
      response = await capturedCancel.run<R>(load(params));
    } on Object catch (error) {
      if (_disposed) return;
      if (!identical(_activeCancel, capturedCancel)) return;
      _error = error;
      _isLoading = false;
      _emit();
      return;
    }

    if (_disposed) return;
    if (!identical(_activeCancel, capturedCancel)) return;
    if (response == null) return;

    final ACParseResult<T> parsed;
    try {
      parsed = parser(response);
    } on Object catch (error) {
      if (_disposed) return;
      if (!identical(_activeCancel, capturedCancel)) return;
      _error = error;
      _isLoading = false;
      _emit();
      return;
    }

    if (_disposed) return;
    if (!identical(_activeCancel, capturedCancel)) return;

    _items.addAll(parsed.items);
    _hasMore = parsed.hasMore;
    _isLoading = false;
    _emit();
  }

  /// Отменить активную загрузку.
  ///
  /// Не сбрасывает накопленные [items] и флаг [hasMore]. Если никакой
  /// загрузки не идёт — безопасный no-op. После [dispose] также безопасен
  /// (ничего не делает).
  Future<void> cancel() async {
    if (_disposed) return;

    await _activeCancel?.cancel();
    if (_disposed) return;

    if (_isLoading) {
      _isLoading = false;
      _emit();
    }
  }

  /// Освободить ресурсы.
  ///
  /// Отменяет активную загрузку (ошибки отмены игнорируются), закрывает
  /// [notifier] и помечает диспатчер как освобождённый. Повторный [dispose]
  /// — идемпотентный no-op. Любые публичные методы, вызванные после
  /// [dispose], становятся no-op и не мутируют состояние.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    try {
      await _activeCancel?.cancel();
    } on Object catch (_) {
      // Ошибки отмены игнорируются — приоритет освобождения ресурсов.
    }

    await _notifier.dispose();
  }

  void _emit() {
    if (_disposed) return;
    _notifier.send(
      ACListLoadingState<T>(
        items: _items,
        isLoading: _isLoading,
        hasMore: _hasMore,
        error: _error,
      ),
    );
  }
}

/// Конкретная реализация [ACNotifier] с включённым `resendLastEvent`.
///
/// [ACNotifier] — абстрактный класс; диспатчеру нужен инстанцируемый
/// подтип, который хранит последний снапшот и переотправляет его новым
/// подписчикам.
final class _ResendingNotifier<T> extends ACNotifier<T> {
  _ResendingNotifier() : super(resendLastEvent: true);
}

import 'dart:async';

import '../../notifier/notifier.dart';
import 'ac_cancel_strategy.dart';
import 'ac_list_loading_params.dart';
import 'ac_list_loading_parser.dart';
import 'ac_list_loading_state.dart';
import 'ac_search_strategy.dart';

/// Диспатчер загрузки списков с пагинацией и поиском.
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
/// Поведение поиска настраивается через [searchStrategy] и применяется
/// только в [reload]: debounce для изменившегося query, очистка items при
/// недостижении `minLength`, мгновенный запуск при пустом или совпавшем
/// query. В [loadMore] поиск игнорируется: query из params передаётся в
/// loader как есть, debounce и проверка minLength не применяются.
final class ACListLoadingDispatcher<T, R> {
  /// Создаёт диспатчер с заданным [parser] и [searchStrategy].
  ///
  /// [parser] вызывается диспатчером синхронно над уже дождавшимся ответом
  /// loader'а. Если парсер бросает исключение — оно перехватывается и
  /// уходит в [error] как ошибка загрузки.
  ///
  /// [searchStrategy] настраивает поисковое поведение (debounce + minLength);
  /// по умолчанию используется `const ACSearchStrategy()` — 300мс задержки,
  /// минимум 3 символа.
  ///
  /// [defaultCancelStrategy] — стратегия отмены по умолчанию для [reload] и
  /// [loadMore]. Применяется приоритет: `cancelStrategy` из аргументов метода
  /// перекрывает [defaultCancelStrategy]; если оба `null` — на каждую
  /// загрузку создаётся новый [ACOperationCancelStrategy].
  ///
  /// Если задан [defaultCancelStrategy] — **один и тот же экземпляр**
  /// используется между вызовами [reload]/[loadMore]. Это означает, что при
  /// старте новой загрузки на нём вызывается `cancel()` (отмена предыдущей),
  /// а затем `run()` — повторно. Реализация должна корректно выдерживать
  /// многократные вызовы `run` (по data-model §7 штатный
  /// [ACOperationCancelStrategy] это поддерживает, так как каждый `run`
  /// создаёт новую `CancelableOperation` внутри). Пользовательские
  /// реализации должны быть готовы к повторным `run` на том же инстансе.
  ACListLoadingDispatcher({
    required this.parser,
    ACSearchStrategy? searchStrategy,
    this.defaultCancelStrategy,
  }) : searchStrategy = searchStrategy ?? ACSearchStrategy() {
    _emit();
  }

  /// Парсер, преобразующий ответ loader'а в [ACParseResult].
  ///
  /// Задаётся один раз при создании диспатчера и далее не меняется.
  final ACListLoadingParser<T, R> parser;

  /// Стратегия поискового поведения.
  ///
  /// Задаётся один раз при создании диспатчера. Управляет debounce-ом и
  /// минимальной длиной query в [reload].
  final ACSearchStrategy searchStrategy;

  /// Стратегия отмены по умолчанию для [reload] и [loadMore].
  ///
  /// Приоритет выбора стратегии при старте загрузки:
  /// 1. `cancelStrategy`, переданный в [reload]/[loadMore] аргументом;
  /// 2. [defaultCancelStrategy];
  /// 3. новый экземпляр [ACOperationCancelStrategy] на каждую загрузку.
  ///
  /// Если [defaultCancelStrategy] задан — один и тот же экземпляр
  /// переиспользуется между вызовами, поэтому его реализация должна
  /// выдерживать многократные вызовы `run` (штатный
  /// [ACOperationCancelStrategy] это гарантирует).
  final ACCancelStrategy? defaultCancelStrategy;

  final List<T> _items = <T>[];
  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  bool _disposed = false;
  ACCancelStrategy? _activeCancel;
  String? _lastAppliedQuery;
  Timer? _debounceTimer;

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
  /// Поведение зависит от `params.query` и [searchStrategy]:
  /// - `null`/пустой: `_lastAppliedQuery` сбрасывается, загрузка стартует
  ///   мгновенно без debounce;
  /// - короче `searchStrategy.minLength`: items очищаются,
  ///   `hasMore = false`, loader **не** вызывается; `_lastAppliedQuery`
  ///   запоминается, чтобы повторный reload с тем же коротким query тоже
  ///   был no-op (кроме повторной очистки);
  /// - совпадает с `_lastAppliedQuery`: загрузка стартует мгновенно;
  /// - изменился и длина `>= minLength`: стартует debounce-таймер на
  ///   `searchStrategy.debounce`. При новом [reload] до срабатывания
  ///   таймера — таймер перезапускается, старый не стартует.
  ///
  /// Если `searchStrategy.debounce == Duration.zero` и query нуждается в
  /// debounce — загрузка всё равно стартует мгновенно (нулевая задержка).
  ///
  /// Во всех случаях активная загрузка (включая debounce-таймер)
  /// отменяется перед стартом новой.
  ///
  /// [load] вызывается диспатчером, получая [params]. Результат
  /// прогоняется через [parser]; элементы из [ACParseResult.items]
  /// **заменяют** текущее содержимое списка, [hasMore] обновляется.
  ///
  /// Исключения loader'а и парсера перехватываются и попадают в [error];
  /// `isLoading` сбрасывается в `false`, элементы не меняются.
  ///
  /// Результат, пришедший после [dispose] или после того, как успели
  /// запустить более новый [reload], игнорируется.
  ///
  /// [cancelStrategy] — опциональная стратегия отмены именно для этой
  /// загрузки. Приоритет: аргумент → [defaultCancelStrategy] → новый
  /// [ACOperationCancelStrategy] на каждый вызов. В ветке отказа по
  /// minLength [cancelStrategy] не используется: загрузка не стартует.
  /// В debounce-ветке параметр захватывается замыканием и применяется
  /// при срабатывании таймера.
  Future<void> reload<P extends ACListLoadingParamsMixin>({
    required P params,
    required Future<R> Function(P params) load,
    ACCancelStrategy? cancelStrategy,
  }) async {
    if (_disposed) return;

    final query = params.query;

    // Любой новый reload сбрасывает предыдущий debounce-таймер.
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // Ветка 1: query пустой / null — мгновенный запуск без debounce.
    if (query == null || query.isEmpty) {
      _lastAppliedQuery = null;
      await _runLoad<P>(
        params: params,
        load: load,
        replace: true,
        cancelStrategy: cancelStrategy,
      );
      return;
    }

    // Ветка 2: query короче minLength — отказ: очищаем items, не грузим.
    if (query.length < searchStrategy.minLength) {
      _lastAppliedQuery = query;

      final previousCancel = _activeCancel;
      _activeCancel = null;
      if (previousCancel != null) {
        await previousCancel.cancel();
      }
      if (_disposed) return;

      _items.clear();
      _hasMore = false;
      _error = null;
      _isLoading = false;
      _emit();
      return;
    }

    // Ветка 3: query совпал с последним применённым — мгновенный запуск.
    if (query == _lastAppliedQuery) {
      await _runLoad<P>(
        params: params,
        load: load,
        replace: true,
        cancelStrategy: cancelStrategy,
      );
      return;
    }

    // Ветка 4: query изменился и удовлетворяет minLength.
    // Если debounce нулевой — грузим сразу.
    if (searchStrategy.debounce == Duration.zero) {
      _lastAppliedQuery = query;
      await _runLoad<P>(
        params: params,
        load: load,
        replace: true,
        cancelStrategy: cancelStrategy,
      );
      return;
    }

    // Иначе — планируем отложенную загрузку через Timer.
    // cancelStrategy захватывается замыканием и применится, когда таймер
    // сработает.
    final capturedStrategy = cancelStrategy;
    _debounceTimer = Timer(searchStrategy.debounce, () {
      _debounceTimer = null;
      if (_disposed) return;
      _lastAppliedQuery = query;
      // Результат _runLoad не await-им внутри колбэка таймера: внешний
      // Future.reload уже разрешён к моменту срабатывания таймера.
      _runLoad<P>(
        params: params,
        load: load,
        replace: true,
        cancelStrategy: capturedStrategy,
      );
    });
  }

  /// Догрузить следующую страницу.
  ///
  /// Игнорируется (без ошибки, без изменения состояния), если:
  /// - уже идёт другая загрузка (`isLoading == true`);
  /// - [hasMore] == `false`;
  /// - диспатчер уже `dispose`-нут.
  ///
  /// Поиск в [loadMore] не применяется: debounce отсутствует, проверка
  /// minLength пропускается, `_lastAppliedQuery` не меняется. Query из
  /// [params] передаётся в [load] как есть.
  ///
  /// Элементы из [ACParseResult.items] **добавляются** в конец
  /// существующего списка; [hasMore] обновляется по результату [parser].
  ///
  /// [cancelStrategy] — опциональная стратегия отмены именно для этой
  /// загрузки. Приоритет: аргумент → [defaultCancelStrategy] → новый
  /// [ACOperationCancelStrategy] на каждый вызов.
  Future<void> loadMore<P extends ACListLoadingParamsMixin>({
    required P params,
    required Future<R> Function(P params) load,
    ACCancelStrategy? cancelStrategy,
  }) async {
    if (_disposed) return;
    if (_isLoading) return;
    if (!_hasMore) return;

    await _runLoad<P>(
      params: params,
      load: load,
      replace: false,
      cancelStrategy: cancelStrategy,
    );
  }

  /// Отменить активную загрузку (включая debounce-таймер).
  ///
  /// Не сбрасывает накопленные [items] и флаг [hasMore]. Если никакой
  /// загрузки не идёт — безопасный no-op. После [dispose] также безопасен
  /// (ничего не делает).
  Future<void> cancel() async {
    if (_disposed) return;

    _debounceTimer?.cancel();
    _debounceTimer = null;

    final previousCancel = _activeCancel;
    _activeCancel = null;
    await previousCancel?.cancel();
    if (_disposed) return;

    if (_isLoading) {
      _isLoading = false;
      _emit();
    }
  }

  /// Освободить ресурсы.
  ///
  /// Отменяет активную загрузку и debounce-таймер (ошибки отмены
  /// игнорируются), закрывает [notifier] и помечает диспатчер как
  /// освобождённый. Повторный [dispose] — идемпотентный no-op. Любые
  /// публичные методы, вызванные после [dispose], становятся no-op и не
  /// мутируют состояние.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _debounceTimer?.cancel();
    _debounceTimer = null;

    try {
      await _activeCancel?.cancel();
    } on Object catch (_) {
      // Ошибки отмены игнорируются — приоритет освобождения ресурсов.
    }

    await _notifier.dispose();
  }

  /// Общая процедура выполнения загрузки для [reload] и [loadMore].
  ///
  /// При `replace == true` накопленные элементы заменяются результатом
  /// парсера; при `replace == false` — добавляются в конец (loadMore).
  ///
  /// [cancelStrategy] выбирается по приоритету: аргумент →
  /// [defaultCancelStrategy] → новый [ACOperationCancelStrategy]. Выбранный
  /// экземпляр сохраняется в `_activeCancel`, чтобы следующий [reload] мог
  /// его отменить.
  Future<void> _runLoad<P extends ACListLoadingParamsMixin>({
    required P params,
    required Future<R> Function(P params) load,
    required bool replace,
    ACCancelStrategy? cancelStrategy,
  }) async {
    if (_disposed) return;

    final previousCancel = _activeCancel;
    final capturedCancel = cancelStrategy
        ?? defaultCancelStrategy
        ?? ACOperationCancelStrategy();
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

    if (replace) {
      _items
        ..clear()
        ..addAll(parsed.items);
    } else {
      _items.addAll(parsed.items);
    }
    _hasMore = parsed.hasMore;
    _isLoading = false;
    _emit();
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

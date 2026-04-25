import 'package:flutter/foundation.dart';

import 'ac_cancel_strategy.dart';
import 'ac_list_loading_params.dart';
import 'ac_list_loading_result.dart';
import 'ac_search_strategy.dart';

/// Диспатчер загрузки списков с offset-пагинацией и поиском, где loader
/// возвращает «голый» `List<T>`.
///
/// Инкапсулирует жизненный цикл загрузок: `reload` перезапускает список с
/// нуля, `loadMore` догружает следующую страницу, `cancel` снимает активную
/// загрузку без сброса накопленных элементов, `dispose` освобождает ресурсы.
///
/// Диспатчер наследуется от [ChangeNotifier]. Состояние доступно через
/// геттеры [items], [isLoading], [hasMore]; [notifyListeners] вызывается
/// только при **изменении [items]** — подписчики `ChangeNotifier` перечитают
/// `items` и сами обновят UI. Изменения [isLoading] или [hasMore] без
/// изменения [items] нотификацию не вызывают; если потребителю нужен
/// спиннер — состояние [isLoading] можно прочитать синхронно до/после
/// `reload`/`loadMore` (например, оборачивая вызов в `setState`).
///
/// Generic-параметр класса:
/// - [T] — тип элемента списка.
///
/// Тип параметров загрузки `P` задаётся generic-методом и должен подмешать
/// [ACOffsetListLoadingParamsMixin]: диспатчер вычисляет `hasMore` как
/// `result.length >= params.limit`. Если `params.limit == null`, считается,
/// что источник лимита не имеет и страницы могут продолжаться бесконечно
/// (`hasMore == true`).
///
/// Поведение поиска настраивается через [searchStrategy] и применяется
/// только в [reload]: debounce для изменившегося query, отказ при
/// недостижении `minLength` (с очисткой items), мгновенный запуск при
/// пустом или совпавшем query. В [loadMore] поиск игнорируется: query
/// из params передаётся в loader как есть, debounce и проверка minLength
/// не применяются.
///
/// Ошибки loader'а **не** перехватываются: исключение, брошенное внутри
/// `load(params)`, пробрасывается наружу из [reload]/[loadMore]. Флаг
/// [isLoading] при этом гарантированно сбрасывается (через `try/finally`).
///
/// Пример:
///
/// ```dart
/// final dispatcher = ACDefaultListLoadingDispatcher<User>();
/// await dispatcher.reload(
///   params: const UserListParams(offset: 0, limit: 20),
///   load: (p) => api.fetchUsers(offset: p.offset, limit: p.limit),
/// );
/// ```
final class ACDefaultListLoadingDispatcher<T> extends ChangeNotifier {
  /// Создаёт диспатчер с опциональной [searchStrategy].
  ///
  /// Если [searchStrategy] не передан — используется
  /// [ACDebouncedSearchStrategy] с дефолтами (debounce `300мс`,
  /// `minLength = 3`). Стратегия задаётся один раз и далее не меняется.
  ACDefaultListLoadingDispatcher({
    ACSearchStrategy? searchStrategy,
  }) : searchStrategy = searchStrategy ?? ACDebouncedSearchStrategy();

  /// Стратегия поискового поведения, применяемая в [reload].
  final ACSearchStrategy searchStrategy;

  final List<T> _items = <T>[];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _disposed = false;
  ACCancelStrategy? _activeCancel;

  /// Неизменяемый список накопленных элементов.
  ///
  /// Возвращается через `List.unmodifiable` — попытка мутировать снаружи
  /// вызывает `UnsupportedError`.
  List<T> get items => List<T>.unmodifiable(_items);

  /// Идёт ли сейчас загрузка.
  ///
  /// Читается синхронно; [notifyListeners] при изменении этого флага
  /// **не** вызывается. Если нужен реактивный спиннер — оборачивайте
  /// вызов `reload`/`loadMore` в `setState`/аналог.
  bool get isLoading => _isLoading;

  /// Есть ли ещё элементы для догрузки через [loadMore].
  ///
  /// Читается синхронно; [notifyListeners] при изменении этого флага
  /// **без** изменения [items] не вызывается.
  bool get hasMore => _hasMore;

  /// Перезагрузить список.
  ///
  /// Поведение определяется [searchStrategy]. Стратегия получает
  /// `params.query` и возвращает:
  /// - `null` — отказ по `minLength`: items очищаются, `hasMore = false`,
  ///   loader **не** вызывается. [notifyListeners] вызывается только если
  ///   список был непустым (то есть [items] действительно изменились);
  /// - `Future<void>` — загрузку нужно стартовать по её завершению
  ///   (мгновенно или после debounce). По резолву `Future` диспатчер
  ///   запускает loader, заменяет накопленные элементы результатом и
  ///   вызывает [notifyListeners].
  ///
  /// Активная загрузка отменяется перед стартом новой через ранее
  /// сохранённый [ACCancelStrategy].
  ///
  /// [load] вызывается с переданными [params] и возвращает `Future<List<T>>`
  /// — результат интерпретируется как сами элементы страницы. `hasMore`
  /// вычисляется как `result.length >= params.limit` (или `true`, если
  /// `params.limit == null`). Исключения loader'а **пробрасываются
  /// наружу**; флаг [isLoading] при этом сбрасывается до того, как
  /// исключение покинет метод.
  ///
  /// Результат, пришедший после [dispose] или после того, как успели
  /// стартовать более новый [reload], игнорируется (не применяется к
  /// состоянию и не нотифицирует).
  ///
  /// [cancelStrategy] — опциональная стратегия отмены именно для этой
  /// загрузки. Приоритет: аргумент → новый [ACOperationCancelStrategy]
  /// на каждый вызов. В ветке отказа по minLength [cancelStrategy] не
  /// используется: загрузка не стартует.
  Future<void> reload<P extends ACOffsetListLoadingParamsMixin>({
    required P params,
    required Future<List<T>> Function(P params) load,
    ACCancelStrategy? cancelStrategy,
  }) async {
    if (_disposed) return;

    // Выставляем флаг загрузки СИНХРОННО, чтобы вызывающий код сразу после
    // `dispatcher.reload(...)` увидел `isLoading == true` без ожидания
    // debounce-а или внутренних await-ов.
    _isLoading = true;

    final schedule = searchStrategy.schedule(params.query);
    if (schedule == null) {
      // Отказ по minLength — очищаем items.
      final previousCancel = _activeCancel;
      _activeCancel = null;
      if (previousCancel != null) {
        await previousCancel.cancel();
      }
      if (_disposed) return;

      final wasNonEmpty = _items.isNotEmpty;
      _items.clear();
      _hasMore = false;
      _isLoading = false;
      if (wasNonEmpty) notifyListeners();
      return;
    }

    await schedule;
    if (_disposed) return;

    await _runLoad<P>(
      params: params,
      load: load,
      replace: true,
      cancelStrategy: cancelStrategy,
    );
  }

  /// Догрузить следующую страницу.
  ///
  /// Игнорируется (без ошибки, без изменения состояния), если:
  /// - уже идёт другая загрузка (`isLoading == true`);
  /// - [hasMore] == `false`;
  /// - диспатчер уже `dispose`-нут.
  ///
  /// Поиск в [loadMore] не применяется: [searchStrategy] не вызывается,
  /// debounce отсутствует, проверка minLength пропускается. Query из
  /// [params] передаётся в [load] как есть.
  ///
  /// Элементы из результата loader'а **добавляются** в конец существующего
  /// списка; [hasMore] обновляется как `result.length >= params.limit` (или
  /// `true`, если `params.limit == null`). По успешной догрузке вызывается
  /// [notifyListeners].
  ///
  /// Исключения loader'а **пробрасываются наружу**; флаг [isLoading] при
  /// этом сбрасывается до того, как исключение покинет метод. Накопленные
  /// элементы не мутируются в случае ошибки.
  ///
  /// [cancelStrategy] — опциональная стратегия отмены именно для этой
  /// загрузки. Приоритет: аргумент → новый [ACOperationCancelStrategy]
  /// на каждый вызов.
  Future<void> loadMore<P extends ACOffsetListLoadingParamsMixin>({
    required P params,
    required Future<List<T>> Function(P params) load,
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

  /// Отменить активную загрузку (включая pending-таймер в [searchStrategy]).
  ///
  /// Не сбрасывает накопленные [items] и флаг [hasMore]. Если никакой
  /// загрузки не идёт — безопасный no-op. После [dispose] также безопасен
  /// (ничего не делает). [notifyListeners] не вызывается, так как [items]
  /// не меняются.
  Future<void> cancel() async {
    if (_disposed) return;

    searchStrategy.cancel();

    final previousCancel = _activeCancel;
    _activeCancel = null;
    await previousCancel?.cancel();
    if (_disposed) return;

    _isLoading = false;
  }

  /// Освободить ресурсы.
  ///
  /// Отменяет активную загрузку и pending-таймер [searchStrategy] (ошибки
  /// отмены игнорируются), освобождает ресурсы стратегии поиска и
  /// помечает диспатчер как освобождённый. Повторный [dispose] —
  /// идемпотентный no-op. Любые публичные методы, вызванные после
  /// [dispose], становятся no-op и не мутируют состояние.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    searchStrategy.dispose();

    // Отмена активной загрузки — fire-and-forget: ошибки игнорируются,
    // приоритет освобождения ресурсов.
    final previousCancel = _activeCancel;
    _activeCancel = null;
    if (previousCancel != null) {
      // Не await-им: dispose ChangeNotifier синхронный. Результат cancel
      // уже никому не нужен.
      previousCancel.cancel().ignore();
    }

    super.dispose();
  }

  /// Общая процедура выполнения загрузки для [reload] и [loadMore].
  ///
  /// При `replace == true` накопленные элементы заменяются результатом
  /// loader'а; при `replace == false` — добавляются в конец (loadMore).
  ///
  /// [cancelStrategy] выбирается по приоритету: аргумент → новый
  /// [ACOperationCancelStrategy]. Выбранный экземпляр сохраняется в
  /// `_activeCancel`, чтобы следующий [reload] мог его отменить.
  ///
  /// Извлечение элементов: результат loader'а — это сами `items`. `hasMore`
  /// вычисляется как `result.length >= params.limit` (или `true`, если
  /// `params.limit == null`). Исключения loader'а не перехватываются:
  /// `try/finally` гарантирует сброс [_isLoading] до пробрасывания
  /// исключения наружу.
  Future<void> _runLoad<P extends ACOffsetListLoadingParamsMixin>({
    required P params,
    required Future<List<T>> Function(P params) load,
    required bool replace,
    ACCancelStrategy? cancelStrategy,
  }) async {
    if (_disposed) return;

    final previousCancel = _activeCancel;
    final capturedCancel = cancelStrategy ?? ACOperationCancelStrategy();
    _activeCancel = capturedCancel;
    _isLoading = true;

    if (previousCancel != null) {
      await previousCancel.cancel();
    }
    if (_disposed || !identical(_activeCancel, capturedCancel)) {
      return;
    }

    try {
      final result = await capturedCancel.run<List<T>>(load(params));
      if (_disposed || !identical(_activeCancel, capturedCancel)) return;
      if (result == null) return; // отменено

      final limit = params.limit;
      final newHasMore = limit == null || result.length >= limit;

      if (replace) {
        _items
          ..clear()
          ..addAll(result);
      } else {
        _items.addAll(result);
      }
      _hasMore = newHasMore;
      notifyListeners();
    } finally {
      if (!_disposed && identical(_activeCancel, capturedCancel)) {
        _isLoading = false;
      }
    }
  }
}

/// Диспатчер загрузки списков с пагинацией и поиском, где loader возвращает
/// DTO, подмешавший [ACListLoadingResult].
///
/// Инкапсулирует жизненный цикл загрузок: `reload` перезапускает список с
/// нуля, `loadMore` догружает следующую страницу, `cancel` снимает активную
/// загрузку без сброса накопленных элементов, `dispose` освобождает ресурсы.
///
/// Диспатчер наследуется от [ChangeNotifier]. Состояние доступно через
/// геттеры [items], [isLoading], [hasMore]; [notifyListeners] вызывается
/// только при **изменении [items]** — подписчики `ChangeNotifier` перечитают
/// `items` и сами обновят UI. Изменения [isLoading] или [hasMore] без
/// изменения [items] нотификацию не вызывают; если потребителю нужен
/// спиннер — состояние [isLoading] можно прочитать синхронно до/после
/// `reload`/`loadMore` (например, оборачивая вызов в `setState`).
///
/// Generic-параметры класса:
/// - [R] — тип результата loader'а, обязательно подмешавший
///   [ACListLoadingResult] с тем же типом элементов [T];
/// - [T] — тип элемента списка.
///
/// Тип параметров загрузки `P` задаётся generic-методом и расширяет
/// [ACListLoadingParamsMixin] (offset или cursor — на усмотрение
/// потребителя). Извлечение элементов и `hasMore` берётся напрямую из
/// геттеров `result.items` и `result.hasMore`.
///
/// Поведение поиска настраивается через [searchStrategy] и применяется
/// только в [reload]: debounce для изменившегося query, отказ при
/// недостижении `minLength` (с очисткой items), мгновенный запуск при
/// пустом или совпавшем query. В [loadMore] поиск игнорируется: query
/// из params передаётся в loader как есть, debounce и проверка minLength
/// не применяются.
///
/// Ошибки loader'а **не** перехватываются: исключение, брошенное внутри
/// `load(params)`, пробрасывается наружу из [reload]/[loadMore]. Флаг
/// [isLoading] при этом гарантированно сбрасывается (через `try/finally`).
///
/// Пример:
///
/// ```dart
/// final dispatcher = ACCustomListLoadingDispatcher<UserPage, User>();
/// await dispatcher.reload(
///   params: const UserCursorParams(cursor: null),
///   load: (p) => api.fetchUsers(cursor: p.cursor),
/// );
/// ```
final class ACCustomListLoadingDispatcher<R extends ACListLoadingResult<T>, T>
    extends ChangeNotifier {
  /// Создаёт диспатчер с опциональной [searchStrategy].
  ///
  /// Если [searchStrategy] не передан — используется
  /// [ACDebouncedSearchStrategy] с дефолтами (debounce `300мс`,
  /// `minLength = 3`). Стратегия задаётся один раз и далее не меняется.
  ACCustomListLoadingDispatcher({
    ACSearchStrategy? searchStrategy,
  }) : searchStrategy = searchStrategy ?? ACDebouncedSearchStrategy();

  /// Стратегия поискового поведения, применяемая в [reload].
  final ACSearchStrategy searchStrategy;

  final List<T> _items = <T>[];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _disposed = false;
  ACCancelStrategy? _activeCancel;

  /// Неизменяемый список накопленных элементов.
  ///
  /// Возвращается через `List.unmodifiable` — попытка мутировать снаружи
  /// вызывает `UnsupportedError`.
  List<T> get items => List<T>.unmodifiable(_items);

  /// Идёт ли сейчас загрузка.
  ///
  /// Читается синхронно; [notifyListeners] при изменении этого флага
  /// **не** вызывается. Если нужен реактивный спиннер — оборачивайте
  /// вызов `reload`/`loadMore` в `setState`/аналог.
  bool get isLoading => _isLoading;

  /// Есть ли ещё элементы для догрузки через [loadMore].
  ///
  /// Читается синхронно; [notifyListeners] при изменении этого флага
  /// **без** изменения [items] не вызывается.
  bool get hasMore => _hasMore;

  /// Перезагрузить список.
  ///
  /// Поведение определяется [searchStrategy]. Стратегия получает
  /// `params.query` и возвращает:
  /// - `null` — отказ по `minLength`: items очищаются, `hasMore = false`,
  ///   loader **не** вызывается. [notifyListeners] вызывается только если
  ///   список был непустым (то есть [items] действительно изменились);
  /// - `Future<void>` — загрузку нужно стартовать по её завершению
  ///   (мгновенно или после debounce). По резолву `Future` диспатчер
  ///   запускает loader, заменяет накопленные элементы значениями
  ///   `result.items` и вызывает [notifyListeners].
  ///
  /// Активная загрузка отменяется перед стартом новой через ранее
  /// сохранённый [ACCancelStrategy].
  ///
  /// [load] вызывается с переданными [params] и возвращает `Future<R>` —
  /// DTO с геттерами [ACListLoadingResult.items] и
  /// [ACListLoadingResult.hasMore], которые читаются напрямую. Исключения
  /// loader'а **пробрасываются наружу**; флаг [isLoading] при этом
  /// сбрасывается до того, как исключение покинет метод.
  ///
  /// Результат, пришедший после [dispose] или после того, как успели
  /// стартовать более новый [reload], игнорируется (не применяется к
  /// состоянию и не нотифицирует).
  ///
  /// [cancelStrategy] — опциональная стратегия отмены именно для этой
  /// загрузки. Приоритет: аргумент → новый [ACOperationCancelStrategy]
  /// на каждый вызов. В ветке отказа по minLength [cancelStrategy] не
  /// используется: загрузка не стартует.
  Future<void> reload<P extends ACListLoadingParamsMixin>({
    required P params,
    required Future<R> Function(P params) load,
    ACCancelStrategy? cancelStrategy,
  }) async {
    if (_disposed) return;

    // Выставляем флаг загрузки СИНХРОННО, чтобы вызывающий код сразу после
    // `dispatcher.reload(...)` увидел `isLoading == true` без ожидания
    // debounce-а или внутренних await-ов.
    _isLoading = true;

    final schedule = searchStrategy.schedule(params.query);
    if (schedule == null) {
      // Отказ по minLength — очищаем items.
      final previousCancel = _activeCancel;
      _activeCancel = null;
      if (previousCancel != null) {
        await previousCancel.cancel();
      }
      if (_disposed) return;

      final wasNonEmpty = _items.isNotEmpty;
      _items.clear();
      _hasMore = false;
      _isLoading = false;
      if (wasNonEmpty) notifyListeners();
      return;
    }

    await schedule;
    if (_disposed) return;

    await _runLoad<P>(
      params: params,
      load: load,
      replace: true,
      cancelStrategy: cancelStrategy,
    );
  }

  /// Догрузить следующую страницу.
  ///
  /// Игнорируется (без ошибки, без изменения состояния), если:
  /// - уже идёт другая загрузка (`isLoading == true`);
  /// - [hasMore] == `false`;
  /// - диспатчер уже `dispose`-нут.
  ///
  /// Поиск в [loadMore] не применяется: [searchStrategy] не вызывается,
  /// debounce отсутствует, проверка minLength пропускается. Query из
  /// [params] передаётся в [load] как есть.
  ///
  /// Элементы из `result.items` **добавляются** в конец существующего
  /// списка; [hasMore] обновляется значением `result.hasMore`. По успешной
  /// догрузке вызывается [notifyListeners].
  ///
  /// Исключения loader'а **пробрасываются наружу**; флаг [isLoading] при
  /// этом сбрасывается до того, как исключение покинет метод. Накопленные
  /// элементы не мутируются в случае ошибки.
  ///
  /// [cancelStrategy] — опциональная стратегия отмены именно для этой
  /// загрузки. Приоритет: аргумент → новый [ACOperationCancelStrategy]
  /// на каждый вызов.
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

  /// Отменить активную загрузку (включая pending-таймер в [searchStrategy]).
  ///
  /// Не сбрасывает накопленные [items] и флаг [hasMore]. Если никакой
  /// загрузки не идёт — безопасный no-op. После [dispose] также безопасен
  /// (ничего не делает). [notifyListeners] не вызывается, так как [items]
  /// не меняются.
  Future<void> cancel() async {
    if (_disposed) return;

    searchStrategy.cancel();

    final previousCancel = _activeCancel;
    _activeCancel = null;
    await previousCancel?.cancel();
    if (_disposed) return;

    _isLoading = false;
  }

  /// Освободить ресурсы.
  ///
  /// Отменяет активную загрузку и pending-таймер [searchStrategy] (ошибки
  /// отмены игнорируются), освобождает ресурсы стратегии поиска и
  /// помечает диспатчер как освобождённый. Повторный [dispose] —
  /// идемпотентный no-op. Любые публичные методы, вызванные после
  /// [dispose], становятся no-op и не мутируют состояние.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    searchStrategy.dispose();

    // Отмена активной загрузки — fire-and-forget: ошибки игнорируются,
    // приоритет освобождения ресурсов.
    final previousCancel = _activeCancel;
    _activeCancel = null;
    if (previousCancel != null) {
      // Не await-им: dispose ChangeNotifier синхронный. Результат cancel
      // уже никому не нужен.
      previousCancel.cancel().ignore();
    }

    super.dispose();
  }

  /// Общая процедура выполнения загрузки для [reload] и [loadMore].
  ///
  /// При `replace == true` накопленные элементы заменяются `result.items`;
  /// при `replace == false` — добавляются в конец (loadMore).
  ///
  /// [cancelStrategy] выбирается по приоритету: аргумент → новый
  /// [ACOperationCancelStrategy]. Выбранный экземпляр сохраняется в
  /// `_activeCancel`, чтобы следующий [reload] мог его отменить.
  ///
  /// Извлечение элементов и `hasMore` идёт напрямую через
  /// [ACListLoadingResult.items] и [ACListLoadingResult.hasMore]. Исключения
  /// loader'а не перехватываются: `try/finally` гарантирует сброс
  /// [_isLoading] до пробрасывания исключения наружу.
  Future<void> _runLoad<P extends ACListLoadingParamsMixin>({
    required P params,
    required Future<R> Function(P params) load,
    required bool replace,
    ACCancelStrategy? cancelStrategy,
  }) async {
    if (_disposed) return;

    final previousCancel = _activeCancel;
    final capturedCancel = cancelStrategy ?? ACOperationCancelStrategy();
    _activeCancel = capturedCancel;
    _isLoading = true;

    if (previousCancel != null) {
      await previousCancel.cancel();
    }
    if (_disposed || !identical(_activeCancel, capturedCancel)) {
      return;
    }

    try {
      final result = await capturedCancel.run<R>(load(params));
      if (_disposed || !identical(_activeCancel, capturedCancel)) return;
      if (result == null) return; // отменено

      final newItems = result.items;
      final newHasMore = result.hasMore;

      if (replace) {
        _items
          ..clear()
          ..addAll(newItems);
      } else {
        _items.addAll(newItems);
      }
      _hasMore = newHasMore;
      notifyListeners();
    } finally {
      if (!_disposed && identical(_activeCancel, capturedCancel)) {
        _isLoading = false;
      }
    }
  }
}

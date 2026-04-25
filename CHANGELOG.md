# appcraft_utils_flutter

<!--
Шаблон для будущих версий CHANGELOG.md:
## <version>

- Краткое описание изменений (императивный стиль, настоящее время).
- Список ключевых изменений:
  - Что добавлено.
  - Что изменено.
  - Что исправлено.
  - Что удалено или устарело.
- Каждое изменение — отдельный пункт, без лишних деталей реализации.
-->

## 0.1.0

### Changed (Phase 10)

- `ACListLoadingDispatcher<P, R, T>` (базовый класс) и парсер-стратегия (`ACListLoadingParser`, `ACDefaultListLoadingParser`, `ACResultListLoadingParser`) удалены. Это откатывает архитектурное решение Phase 9, где базовый класс и парсер вводились как точка расширения.
- `ACDefaultListLoadingDispatcher` и `ACCustomListLoadingDispatcher` стали полностью независимыми классами (оба `extends ChangeNotifier`).
- `P` (тип параметров) убран из generic-ов классов, перенесён в generic-методы `reload`/`loadMore`. У `ACDefaultListLoadingDispatcher` теперь 1 generic в классе (`T`); у `ACCustomListLoadingDispatcher` — 2 (`R`, `T`).
- Конструкторы обоих диспатчеров принимают только опциональный `searchStrategy`; обязательного параметра `parser` больше нет.
- Адаптация экзотического формата ответа теперь делается на стороне потребителя: ответ API оборачивается в свой DTO с миксином `ACListLoadingResult<T>` и используется с `ACCustomListLoadingDispatcher`.

### Added

- Добавлен `ACDefaultListLoadingDispatcher<T>` — независимый диспатчер для типичной offset-пагинации с loader'ом, возвращающим `Future<List<T>>`.
  - `extends ChangeNotifier` из `package:flutter/foundation.dart`; подписка через `addListener` / `ListenableBuilder`.
  - Generic-методы `reload<P extends ACOffsetListLoadingParamsMixin>` / `loadMore<P extends ACOffsetListLoadingParamsMixin>`; тип `P` выводится Dart из аргумента `params`.
  - `hasMore` вычисляется по `params.limit` (полная страница → есть продолжение; `limit == null` → всегда `true`).
  - Методы `cancel` (асинхронный), `dispose` (синхронный).
  - Публичные геттеры: `items` (unmodifiable), `isLoading`, `hasMore`, `searchStrategy`.
  - `notifyListeners()` вызывается только при изменении накопленного списка элементов.
  - Исключения loader'а пробрасываются наружу через возвращённый Future; флаг `isLoading` сбрасывается через `try/finally`.
- Добавлен `ACCustomListLoadingDispatcher<R extends ACListLoadingResult<T>, T>` — независимый диспатчер для loader'ов, возвращающих DTO с миксином `ACListLoadingResult<T>`.
  - `extends ChangeNotifier`; идентичный набор геттеров, методов `cancel`/`dispose` и контракт нотификаций.
  - Generic-методы `reload<P extends ACListLoadingParamsMixin>` / `loadMore<P extends ACListLoadingParamsMixin>` (широкий констрейнт — потребитель сам выбирает между offset/cursor миксином по структуре своего API).
  - Семантика: `items = result.items`, `hasMore = result.hasMore`.
- Миксин `ACListLoadingResult<T>` — контракт DTO (`items`, `hasMore`) для `ACCustomListLoadingDispatcher`.
- Добавлена иерархия миксинов параметров:
  - `ACListLoadingParamsMixin` — базовый контракт (`limit`, `query`).
  - `ACOffsetListLoadingParamsMixin on ACListLoadingParamsMixin` — добавляет `offset` для offset-пагинации.
  - `ACCursorListLoadingParamsMixin on ACListLoadingParamsMixin` — добавляет `cursor` для cursor-пагинации.
  - Диспатчер принимает любой `P extends ACListLoadingParamsMixin` — пользователь выбирает подходящую пару под свой API.
- Добавлена поведенческая стратегия поиска:
  - `abstract class ACSearchStrategy` с методами `schedule`, `cancel`, `dispose`.
  - Дефолтная реализация `ACDebouncedSearchStrategy` (debounce 300 мс / minLength 3); хранит таймер и последний применённый query внутри себя.
- Добавлена стратегия отмены:
  - `abstract class ACCancelStrategy` (`run`, `cancel`, `isActive`).
  - Дефолтная реализация `ACOperationCancelStrategy` на `CancelableOperation` из `package:async`.
  - Параметр `cancelStrategy` задаётся только per-call (в методах `reload`/`loadMore`).
- Поддержка offset, cursor и произвольных стратегий пагинации через миксин `ACListLoadingResult` (без parser-колбэка).
- Пакет теперь Flutter-совместим: явная зависимость от `flutter: sdk: flutter`.
- Новая runtime-зависимость: `async: ^2.11.0`.

## 0.0.3

- Добавлен ACEntityMapper.
- Добавлены ACEnumByNameOrNull и ACEnumComparisonOperators.

## 0.0.2

- Добавлены комментарии в код.
- Изменена валидация `ACRequiredValidation`:
  - Поддержка любых типов значений.
  - Проверка на null.
  - Проверка пустой строки (`String`).
  - Проверка пустой коллекции (`Iterable`).

## 0.0.1

- Начальная версия.

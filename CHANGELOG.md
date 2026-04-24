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

- Добавлен `ACListLoadingDispatcher<T, R>` — доменный компонент для загрузки списков с пагинацией и поиском:
  - Методы `reload`, `loadMore`, `cancel`, `dispose`.
  - Наблюдаемое состояние через `ACNotifier<ACListLoadingState<T>>` (items, isLoading, hasMore, error).
  - `ACSearchStrategy` — встроенный debounce (300мс) и minLength (3) для поиска в `reload`.
  - `ACCancelStrategy` + дефолтная `ACOperationCancelStrategy` на `CancelableOperation` из `package:async`.
  - Override стратегии отмены per-call и через конструктор.
  - `ACListLoadingParamsMixin` — контракт пользовательских параметров (limit/offset/query).
  - `ACParseResult<T>` + typedef `ACListLoadingParser<T, R>` — адаптер ответа loader'а.
  - Поддержка offset, cursor и произвольных стратегий пагинации через parser-колбэк.
- Новая зависимость: `async: ^2.11.0`.

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

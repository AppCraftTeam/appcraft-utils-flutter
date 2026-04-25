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

## 0.1.0 - 2026-04-25

- Prepared for the first public release on pub.dev.
- Filled in `pubspec.yaml` metadata: `description`, `homepage`, `issue_tracker`, `topics`.
- Removed `environment.flutter` — the package is pure-Dart and does not depend on the Flutter SDK.
- Added `example/` with a minimal demo of the public API (`ACEmail`, `ACText`, `ACEnumByNameOrNull`).
- Documented all public symbols across 7 modules (`exceptions`, `extensions`, `inputs`, `localization`, `mappers`, `models`, `notifier`) with `///` doc-comments.
- Tuned `analysis_options.yaml` to the recommended ruleset with `public_member_api_docs` enabled.

## 0.0.3

- Added `ACEntityMapper`.
- Added `ACEnumByNameOrNull` and `ACEnumComparisonOperators`.

## 0.0.2

- Added in-code comments.
- Updated `ACRequiredValidation`:
  - Supports values of any type.
  - Null check.
  - Empty string check (`String`).
  - Empty collection check (`Iterable`).

## 0.0.1

- Initial version.

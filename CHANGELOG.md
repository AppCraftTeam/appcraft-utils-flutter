# appcraft_utils_flutter

## 0.2.0

### Breaking Changes

- `ACEmail` equality and `hashCode` now include `isRequired`; `ACText` equality and
  `hashCode` now include `minLength` and `maxLength`. Migration: fields with different
  settings are now distinct in a `Set`, as `Map` keys and inside `Equatable` states (for
  example, bloc states), where they used to collapse into one; to compare by value only,
  compare `value` explicitly.
- The minimum `equatable` version is now 2.1.0. Migration: allow `equatable: ^2.1.0` in the
  app if it pins an older version.

### Fixed

- An empty optional `ACEmail` (`isRequired: false`) is now valid; the format is checked only
  for a non-empty value.
- `ACText(minLength: 0)` no longer makes the field required: an empty value is valid unless
  `minLength` is greater than 0.
- `ACNotifier`: after `dispose()`, `listen` and `listenAny` return an already completed
  subscription instead of throwing `StateError`, and a saved event is dropped instead of
  being delivered; `send` after (or during) `dispose()` is ignored; calling `dispose()` again
  is safe.

### Changed

- `ACInput` uses `Equatable` as a mixin instead of the deprecated `EquatableMixin`.
- Formatted `lib/` and `example/` with `dart format`.

## 0.1.1

- Renamed the notifier source file to `lib/src/notifier/src/ac_notifier.dart` (the old name used the Cyrillic letter U+0441 instead of the Latin `c`): it violated the `file_names` lint and lowered the pub.dev "Pass static analysis" score.

## 0.1.0

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

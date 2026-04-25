# appcraft_utils_flutter

[![pub package](https://img.shields.io/pub/v/appcraft_utils_flutter.svg)](https://pub.dev/packages/appcraft_utils_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Lightweight Dart utilities and Flutter-friendly extensions for forms, validations, mappers, models, exceptions, notifiers and localization. Pure-Dart package — no dependencies on `dart:ui` or Flutter widgets.

## Installation

```yaml
dependencies:
  appcraft_utils_flutter: ^0.1.0
```

```bash
dart pub get
```

## Modules

- **`exceptions`** — typed exceptions for common validation errors (`MinLengthException`, `MaxLengthException`, etc.).
- **`extensions`** — `Enum` extensions: `byNameOrNull` for null-safe lookup, comparison operators (`<`, `<=`, `>`, `>=`) for ordered enums.
- **`inputs`** — form field models (`ACInput`, `ACEmail`, `ACText`) and a set of validators (`ACRequiredValidation`, `ACMinLengthValidation`, `ACMaxLengthValidation`, `ACEmailValidation`, `ACRegExpValidation`).
- **`localization`** — abstract contract for localized messages with `ACLocalizationRu` / `ACLocalizationEn` implementations.
- **`mappers`** — `ACEntityMapper<Input, Output>` for safe DTO → domain transformations (`map`, `mapList`, `mapNotNull`).
- **`models`** — `ACIdMixin`, `ACTitleMixin` mixins and a `WrappedValue<T>` wrapper for explicit "no value" emission.
- **`notifier`** — lightweight `ACNotifier<T>` with subscriptions for specific or any value, with optional retain-last semantics.

## Example

See [`example/lib/main.dart`](./example/lib/main.dart) — a runnable Dart CLI that demonstrates `ACEmail` validation, `ACText` validation and null-safe enum lookup via `byNameOrNull`.

```bash
cd example
dart pub get
dart run lib/main.dart
```

## Links

- **Repository**: https://github.com/AppCraftTeam/appcraft-utils-flutter
- **Issue tracker**: https://github.com/AppCraftTeam/appcraft-utils-flutter/issues
- **Changelog**: [CHANGELOG.md](./CHANGELOG.md)

## License

MIT — see [LICENSE](./LICENSE).

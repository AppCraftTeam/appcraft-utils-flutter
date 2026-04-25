# appcraft_utils_flutter example

Minimal Dart CLI demonstrating three pieces of the public API of `appcraft_utils_flutter`:

- `ACEmail` — email validation (valid vs. invalid input).
- `ACText` — text validation with minimum length.
- `ACEnumByNameOrNull.byNameOrNull` — null-safe `Enum` lookup by name.

## Run

```bash
cd example
dart pub get
dart run lib/main.dart
```

Expected output: three sections (`ACEmail`, `ACText`, `ACEnumByNameOrNull`) showing validation errors for the invalid inputs and resolved values for the valid ones.

import '../../../appcraft_utils_flutter.dart';

/// Localization manager.
class ACLocalizationManager {
  /// Private constructor that prevents creating external instances.
  ACLocalizationManager._();

  /// The static single instance of the class.
  static final instance = ACLocalizationManager._();

  /// Map of localizations, where the key is a language code and the value is
  /// a localization object.
  final Map<String, ACLocalization> localizations = {
    'ru': const ACLocalizationRu(),
    'en': const ACLocalizationEn()
  };

  /// The current application locale ('ru' by default).
  String currentLocale = 'ru';

  /// Returns the localization object.
  ///
  /// If [localeName] is given, returns the localization for it, otherwise for
  /// the current locale. If the locale is not found, falls back to Russian.
  ACLocalization localization([String? localeName]) =>
      localizations[localeName ?? currentLocale] ?? const ACLocalizationRu();
}

import '../../../appcraft_utils_flutter.dart';

class ACLocalizationManager {
  ACLocalizationManager._();

  static final instance = ACLocalizationManager._();

  final Map<String, ACLocalization> localizations = {
    'ru': const ACLocalizationRu(),
    'en': const ACLocalizationEn()
  };

  String currentLocale = 'ru';

  ACLocalization localization([String? localeName]) =>
    localizations[localeName ?? currentLocale] ?? const ACLocalizationRu();
}
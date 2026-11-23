import 'package:console/i18n/strings.g.dart';
import 'package:material_ui/material_ui.dart';

export 'package:console/i18n/strings.g.dart' show AppLocale, AppTexts;

/// Texts of the app in the current language, without a `BuildContext` (so they work in the splash, "need more
/// space" and before the router). `LanguageCubit` changes [current]; the rest reads `app.intl`
class AppIntl {
  AppIntl._();

  /// One instance per language, built once
  static final Map<AppLocale, AppTexts> _cache = {
    for (final locale in AppLocale.values) locale: locale.buildSync(),
  };

  static AppLocale current = AppLocale.en;

  static AppTexts get texts => _cache[current]!;

  /// The supported language of a code (`es-MX` → `es`); an unknown one uses the base (`en`)
  static AppLocale resolve(String? languageCode) => AppLocale.values.firstWhere(
    (locale) => locale.languageCode == languageCode,
    orElse: () => AppLocale.en,
  );

  static List<Locale> get supportedLocales =>
      AppLocale.values.map((locale) => Locale(locale.languageCode)).toList();

  /// The Material texts (date picker, tooltips...) of material_ui; the app's own come from slang
  static const List<LocalizationsDelegate<dynamic>> delegates =
      GlobalMaterialLocalizations.delegates;
}

extension AppIntlContext on BuildContext {
  /// The texts of [AppIntl.current], for widgets: it depends on the `MaterialApp`'s locale, so the widget rebuilds
  /// when the language changes (`app.intl` doesn't)
  AppTexts get intl {
    Localizations.localeOf(this);
    return AppIntl.texts;
  }
}

/// Generated file. Do not edit.
///
/// Source: lib/i18n
/// To regenerate, run: `dart run slang`

// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'package:slang/slang.dart';
export 'package:slang/slang.dart';

import 'strings_es.g.dart' as l_es;
part 'strings_en.g.dart';

/// Supported locales.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, AppTexts> {
  en(languageCode: 'en'),
  es(languageCode: 'es');

  const AppLocale({
    required this.languageCode,
    this.scriptCode, // ignore: unused_element, unused_element_parameter
    this.countryCode, // ignore: unused_element, unused_element_parameter
  });

  @override
  final String languageCode;
  @override
  final String? scriptCode;
  @override
  final String? countryCode;

  @override
  Future<AppTexts> build({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async {
    return buildSync(
      overrides: overrides,
      cardinalResolver: cardinalResolver,
      ordinalResolver: ordinalResolver,
    );
  }

  @override
  AppTexts buildSync({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    switch (this) {
      case AppLocale.en:
        return AppTextsEn(
          overrides: overrides,
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        );
      case AppLocale.es:
        return l_es.AppTextsEs(
          overrides: overrides,
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        );
    }
  }
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, AppTexts> {
  AppLocaleUtils._()
    : super(baseLocale: AppLocale.en, locales: AppLocale.values);

  static final instance = AppLocaleUtils._();

  // static aliases (checkout base methods for documentation)
  static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
  static AppLocale parseLocaleParts({
    required String languageCode,
    String? scriptCode,
    String? countryCode,
  }) => instance.parseLocaleParts(
    languageCode: languageCode,
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
  static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

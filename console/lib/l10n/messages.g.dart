/// Generated file. Do not edit.
///
/// Source: lib/l10n
/// To regenerate, run: `dart run slang`

// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'package:slang/slang.dart';
export 'package:slang/slang.dart';

import 'messages_es.g.dart' as l_es;
part 'messages_en.g.dart';

/// Supported locales.
///
/// Usage:
/// - LocaleSettings.setLocale(AppMessagesLocale.en) // set locale
/// - Locale locale = AppMessagesLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppMessagesLocale.en) // locale check
enum AppMessagesLocale with BaseAppLocale<AppMessagesLocale, AppMessages> {
  en(languageCode: 'en'),
  es(languageCode: 'es');

  const AppMessagesLocale({
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
  Future<AppMessages> build({
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
  AppMessages buildSync({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) {
    switch (this) {
      case AppMessagesLocale.en:
        return AppMessagesEn(
          overrides: overrides,
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        );
      case AppMessagesLocale.es:
        return l_es.AppMessagesEs(
          overrides: overrides,
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        );
    }
  }
}

/// Provides utility functions without any side effects.
class AppLocaleUtils
    extends BaseAppLocaleUtils<AppMessagesLocale, AppMessages> {
  AppLocaleUtils._()
    : super(
        baseLocale: AppMessagesLocale.en,
        locales: AppMessagesLocale.values,
      );

  static final instance = AppLocaleUtils._();

  // static aliases (checkout base methods for documentation)
  static AppMessagesLocale parse(String rawLocale) => instance.parse(rawLocale);
  static AppMessagesLocale parseLocaleParts({
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

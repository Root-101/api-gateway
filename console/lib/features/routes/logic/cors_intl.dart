import 'package:console/app_exporter.dart';

extension CorsModelIntl on CorsModel {
  ///its origins in a few characters: `ALL` for `*`, the origin when there's one, else how many
  String get short {
    final intl = app.intl.cors;
    if (allowedOrigins.any(corsAllowsAll)) return intl.all;
    if (allowedOrigins.length == 1) {
      return allowedOrigins.first.replaceFirst(RegExp(r'^[a-z]+://'), '');
    }
    return intl.originsCount(count: allowedOrigins.length);
  }
}

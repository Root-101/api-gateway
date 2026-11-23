import 'package:console/app_exporter.dart';

extension GlobalExceptionIntl on GlobalException {
  /// The text to show, in the current language: with [GlobalExceptionCode.custom] the `message` already is (the
  /// gateway's `detail`); the rest by `code`
  String get intlMessage => switch (code) {
    GlobalExceptionCode.custom => message,
    GlobalExceptionCode.cancelled => app.intl.errors.requestCancelled,
    GlobalExceptionCode.connectionTimeout => app.intl.errors.connectionTimeout,
    GlobalExceptionCode.noConnection => app.intl.errors.noConnection,
    GlobalExceptionCode.receiveTimeout => app.intl.errors.receiveTimeout,
    GlobalExceptionCode.sendTimeout => app.intl.errors.sendTimeout,
    GlobalExceptionCode.transformTimeout => app.intl.errors.transformTimeout,
    GlobalExceptionCode.badCertificate => app.intl.errors.badCertificate,
    GlobalExceptionCode.connectionError => app.intl.errors.connection,
    GlobalExceptionCode.validation => app.intl.errors.validation,
    GlobalExceptionCode.auth => app.intl.errors.auth,
    GlobalExceptionCode.httpStatus => app.intl.errors.status(
      status: statusCode ?? 0,
    ),
    GlobalExceptionCode.serverError => app.intl.errors.server,
    GlobalExceptionCode.unknown => app.intl.errors.unknown,
  };
}

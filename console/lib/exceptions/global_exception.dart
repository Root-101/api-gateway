import 'package:console/app_exporter.dart';

enum GlobalExceptionType { general, auth, validation }

/// What went wrong, without text, so the view translates it (`intlMessage`). [custom]: the `message` can be shown as
/// it is (the gateway's `detail`, already in the request's language); for the rest `message` is an English fallback
/// for the logs
enum GlobalExceptionCode {
  custom,
  cancelled,
  connectionTimeout,
  noConnection,
  receiveTimeout,
  sendTimeout,
  transformTimeout,
  badCertificate,
  connectionError,
  validation,
  auth,
  httpStatus,
  serverError,
  unknown,
}

class GlobalException<T> implements Exception {
  final GlobalExceptionType type;
  final String message;
  final T? data;
  final GlobalExceptionCode code;

  /// HTTP status when the error is an answer of the gateway
  final int? statusCode;

  /// The gateway's stable `code` (`auth.wrong-credentials`), the same in every language: compare it, never the text
  final String? errorCode;

  GlobalException({
    required this.type,
    required this.message,
    this.data,
    this.code = GlobalExceptionCode.custom,
    this.statusCode,
    this.errorCode,
  });

  /// The gateway answered [apiCode], as the error's `code` or in an item of a 422
  bool hasCode(String apiCode) =>
      errorCode == apiCode ||
      (data is List<ValidationError> &&
          (data as List<ValidationError>).any((error) => error.code == apiCode));

  @override
  String toString() {
    return 'GlobalException{type: $type, code: $code, statusCode: $statusCode, errorCode: $errorCode, message: $message, data: $data}';
  }
}

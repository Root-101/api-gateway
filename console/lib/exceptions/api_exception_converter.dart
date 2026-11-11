import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class ApiExceptionConverter {
  static GlobalException parse(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errors.requestCancelled,
        );
      case DioExceptionType.connectionTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errors.connectionTimeout,
        );
      case DioExceptionType.unknown:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errors.noConnection,
        );
      case DioExceptionType.receiveTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errors.receiveTimeout,
        );
      case DioExceptionType.sendTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errors.sendTimeout,
        );
      case DioExceptionType.transformTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errors.transformTimeout,
        );
      case DioExceptionType.badCertificate:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: app.intl.errors.badCertificate,
        );
      case DioExceptionType.connectionError:
        return GlobalException(
          //the gateway now sends CORS headers on 401/403 (next release after 5.0.1), so a connection error is a real network error
          //(before, 401/403 arrived here and it was mapped to auth, logging the user out on any outage)
          type: GlobalExceptionType.general,
          message: app.intl.errors.connection,
        );
      case DioExceptionType.badResponse:
        return _parseBadResponse(error);
    }
  }

  static GlobalException _parseBadResponse(DioException error) {
    final int status = error.response?.statusCode ?? 0;
    final dynamic data = error.response?.data;
    final dynamic violations = data is Map ? data['violations'] : null;

    if (status == 422 && violations is List) {
      return GlobalException(
        type: GlobalExceptionType.validation,
        message: app.intl.errors.validation,
        data: violations
            .whereType<Map<String, dynamic>>()
            .map(ValidationError.fromJson)
            .toList(),
      );
    } else if (status == 401 || status == 403) {
      return GlobalException(
        type: GlobalExceptionType.auth,
        message: app.intl.errors.auth,
        data: data,
      );
    } else if (status >= 500) {
      return GlobalException(
        type: GlobalExceptionType.general,
        message: app.intl.errors.server,
        data: data,
      );
    } else {
      return GlobalException(
        type: GlobalExceptionType.general,
        message: _messageFrom(data) ?? app.intl.errors.status(status: status),
        data: data,
      );
    }
  }

  ///body is an RFC 9457 problem json (`detail` is the message); plain strings came from gateways before 6.0.0
  static String? _messageFrom(dynamic data) {
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      for (final key in ['detail', 'message', 'title']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return null;
  }
}

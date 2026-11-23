import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

/// `message` is an English fallback for the logs; the view shows `intlMessage`
class ApiExceptionConverter {
  static GlobalException parse(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return _network(GlobalExceptionCode.cancelled, 'Request to API server was cancelled');
      case DioExceptionType.connectionTimeout:
        return _network(GlobalExceptionCode.connectionTimeout, 'Connection timeout with API server');
      case DioExceptionType.unknown:
        return _network(GlobalExceptionCode.noConnection, 'Connection to API server failed');
      case DioExceptionType.receiveTimeout:
        return _network(GlobalExceptionCode.receiveTimeout, 'Receive timeout in connection with API server');
      case DioExceptionType.sendTimeout:
        return _network(GlobalExceptionCode.sendTimeout, 'Send timeout with API server');
      case DioExceptionType.transformTimeout:
        return _network(GlobalExceptionCode.transformTimeout, 'Transform timeout processing the API response');
      case DioExceptionType.badCertificate:
        return _network(GlobalExceptionCode.badCertificate, 'Bad certificate');
      case DioExceptionType.connectionError:
        //the gateway sends CORS headers on 401/403 too, so a connection error is a real network error
        return _network(GlobalExceptionCode.connectionError, 'Connection error');
      case DioExceptionType.badResponse:
        return _parseBadResponse(error);
    }
  }

  static GlobalException _network(GlobalExceptionCode code, String message) =>
      GlobalException(type: GlobalExceptionType.general, code: code, message: message);

  /// The gateway answers RFC 9457 problem json (`detail`, `code`, and `errors` in a 422); plain strings came from
  /// gateways before 6.0.0
  static GlobalException _parseBadResponse(DioException error) {
    final int status = error.response?.statusCode ?? 0;
    final dynamic data = error.response?.data;
    final Map<String, dynamic>? problem = data is Map<String, dynamic> ? data : null;
    final Object? code = problem?['code'];
    final String? errorCode = code is String ? code : null;
    final String? detail = _messageFrom(data);

    if (status == 422 && problem?['errors'] is List) {
      return GlobalException(
        type: GlobalExceptionType.validation,
        code: GlobalExceptionCode.validation,
        message: detail ?? 'Validation error',
        statusCode: status,
        errorCode: errorCode,
        data: (problem!['errors'] as List)
            .whereType<Map<String, dynamic>>()
            .map(ValidationError.fromJson)
            .toList(),
      );
    } else if (status == 401 || status == 403) {
      return GlobalException(
        type: GlobalExceptionType.auth,
        code: GlobalExceptionCode.auth,
        message: detail ?? 'Authentication error',
        statusCode: status,
        errorCode: errorCode,
        data: data,
      );
    } else if (status >= 500) {
      return GlobalException(
        type: GlobalExceptionType.general,
        code: GlobalExceptionCode.serverError,
        message: detail ?? 'Server error',
        statusCode: status,
        errorCode: errorCode,
        data: data,
      );
    } else {
      //`detail` comes in the request's language: shown as it is
      return GlobalException(
        type: GlobalExceptionType.general,
        code: detail == null ? GlobalExceptionCode.httpStatus : GlobalExceptionCode.custom,
        message: detail ?? 'HTTP $status',
        statusCode: status,
        errorCode: errorCode,
        data: data,
      );
    }
  }

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

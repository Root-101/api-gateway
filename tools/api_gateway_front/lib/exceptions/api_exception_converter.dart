import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';

class ApiExceptionConverter {
  static GlobalException parse(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: 'Request to API server was cancelled', //TODO: intl
        );
      case DioExceptionType.connectionTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message:
              'Connection timeout with API server. Revisa el internet', //TODO: intl
        );
      case DioExceptionType.unknown:
        return GlobalException(
          type: GlobalExceptionType.general,
          message:
              'Connection to API server failed due to internet connection', //TODO: intl
        );
      case DioExceptionType.receiveTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: 'Receive timeout in connection with API server', //TODO: intl
        );
      case DioExceptionType.sendTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: 'Send timeout with server', //TODO: intl
        );
      case DioExceptionType.transformTimeout:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: 'Timeout processing the API server response', //TODO: intl
        );
      case DioExceptionType.badCertificate:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: 'Bad Certificate', //TODO: intl
        );
      case DioExceptionType.connectionError:
        return GlobalException(
          //the gateway now sends CORS headers on 401/403 (next release after 5.0.1), so a connection error is a real network error
          //(before, 401/403 arrived here and it was mapped to auth, logging the user out on any outage)
          type: GlobalExceptionType.general,
          message: 'Connection Error', //TODO: intl
        );
      case DioExceptionType.badResponse:
        return _parseBadResponse(error);
    }
  }

  static GlobalException _parseBadResponse(DioException error) {
    final int status = error.response?.statusCode ?? 0;
    final dynamic data = error.response?.data;

    if (status == 422 && data is List) {
      return GlobalException(
        type: GlobalExceptionType.validation,
        message: 'Validation error', //TODO: intl
        data: data
            .whereType<Map<String, dynamic>>()
            .map(ValidationError.fromJson)
            .toList(),
      );
    } else if (status == 401 || status == 403) {
      return GlobalException(
        type: GlobalExceptionType.auth,
        message: 'Auth error',
        data: data,
      );
    } else if (status >= 500) {
      return GlobalException(
        type: GlobalExceptionType.general,
        message: 'Server error',
        data: data,
      );
    } else {
      return GlobalException(
        type: GlobalExceptionType.general,
        message: _messageFrom(data) ?? 'Error $status',
        data: data,
      );
    }
  }

  ///body can be a plain string (ApiException) or a ProblemDetail json (spring ErrorResponse)
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

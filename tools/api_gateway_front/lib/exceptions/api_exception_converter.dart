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
      case DioExceptionType.badCertificate:
        return GlobalException(
          type: GlobalExceptionType.general,
          message: 'Bad Certificate', //TODO: intl
        );
      case DioExceptionType.connectionError:
        return GlobalException(
          //in web, dio handle 403/401 as a connection error, some weird stuff with navigator closing the connection
          //all other status 200,404,422, work ok, only 403/401, so we gonna handle this connection error as an auth exception
          type: GlobalExceptionType.auth,
          message: 'Connection Error', //TODO: intl
        );
      case DioExceptionType.badResponse:
        return _parseBadResponse(error);
    }
  }

  static GlobalException _parseBadResponse(DioException error) {
    if (error.response!.statusCode == 422) {
      return GlobalException(
        type: GlobalExceptionType.validation,
        message: 'Validation error', //TODO: intl
        data:
            (error.response!.data as List<dynamic>)
                .map(
                  (json) =>
                      ValidationError.fromJson(json as Map<String, dynamic>),
                )
                .toList(),
      );
    } else if (error.response!.statusCode! == 401 ||
        error.response!.statusCode! == 403) {
      return GlobalException(
        type: GlobalExceptionType.auth,
        message: 'Auth error',
        data: error.response!.data,
      );
    } else if (error.response!.statusCode! >= 500) {
      return GlobalException(
        type: GlobalExceptionType.general,
        message: 'Server error',
        data: error.response!.data,
      );
    } else {
      return GlobalException(
        type: GlobalExceptionType.general,
        message: error.response!.data,
        data: error.response!.data,
      );
    }
  }
}

import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';

class ExceptionConverter {
  static GlobalException parse(dynamic exception) {
    return switch (exception) {
      GlobalException() => exception,
      DioException() => ApiExceptionConverter.parse(exception),
      _ => GlobalException(
        type: GlobalExceptionType.general,
        message: 'Unknown error', //TODO: intl
        data: exception,
      ),
    };
  }
}

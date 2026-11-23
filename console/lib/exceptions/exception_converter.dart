import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class ExceptionConverter {
  static GlobalException parse(dynamic exception) {
    return switch (exception) {
      GlobalException() => exception,
      DioException() => ApiExceptionConverter.parse(exception),
      _ => GlobalException(
        type: GlobalExceptionType.general,
        code: GlobalExceptionCode.unknown,
        message: 'Unknown error',
        data: exception,
      ),
    };
  }
}

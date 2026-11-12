import 'package:dio/dio.dart';

abstract class BaseClient {
  String get baseUrl;

  final Dio dio;

  BaseClient(this.dio);
}

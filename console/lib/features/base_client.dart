import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';

abstract class BaseClient {
  String get baseUrl;

  final Dio dio;

  BaseClient(this.dio);

  Options options({CredentialsModel? credential}) {
    return Options(
      headers: <String, dynamic>{
        if (credential != null) 'authorization': 'Bearer ${credential.token}',
      },
    );
  }
}

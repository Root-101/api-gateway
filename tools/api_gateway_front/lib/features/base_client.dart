import 'dart:convert';
import 'dart:io';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart' hide Headers;
import 'package:dio/dio.dart';

abstract class BaseClient {
  String get baseUrl;

  final Dio dio;

  BaseClient(this.dio);

  Options options({CredentialsModel? credential}) {
    final credentials =
        credential != null
            ? base64Encode(
              utf8.encode('${credential.username}:${credential.password}'),
            )
            : null;
    return Options(
      headers: <String, dynamic>{
        if (credentials != null)
          HttpHeaders.authorizationHeader: 'Basic $credentials',
      },
    );
  }
}

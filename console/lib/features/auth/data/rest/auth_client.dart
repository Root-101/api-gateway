import 'package:api_gateway_front/app_exporter.dart';

class AuthClient extends BaseClient {
  @override
  String get baseUrl => '${Environment.baseApiUrl}/auth'; //https://api-gateway.site.com/_admin/auth

  AuthClient(super.dio);

  Future login({required String username, required String password}) async {
    //if this runs without problem, the login is successfully, if something is wrong an exception is thrown
    await dio.post(
      '$baseUrl/login', //https://api-gateway.site.com/_admin/auth/login
      options: options(),
      data: {'username': username, 'password': password},
    );
  }

  ///GET /{ADMIN_PATH}/health: no auth, 200 {"status":"UP"}, 503 when the db is down
  Future health() async {
    await dio.get('${Environment.baseApiUrl}/health', options: options());
  }
}

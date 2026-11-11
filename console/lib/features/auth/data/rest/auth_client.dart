import 'package:console/app_exporter.dart';

class AuthClient extends BaseClient {
  @override
  String get baseUrl => '${Environment.baseApiUrl}/auth'; //https://api-gateway.site.com/_admin/auth

  AuthClient(super.dio);

  ///returns the session token. `expires_in`/`expire_at` are not read: an expired token gets a 401, which asks to sign in again
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await dio.post(
      '$baseUrl/login', //https://api-gateway.site.com/_admin/auth/login
      data: {'username': username, 'password': password},
    );
    final data = response.data;
    final token = data is Map ? data['access_token'] : null;
    if (token is! String || token.isEmpty) {
      throw const FormatException('Login response without token');
    }
    return token;
  }

  ///GET /{ADMIN_PATH}/health: no auth, 200 {"status":"up"}, 503 {"status":"down"} when the db is down
  Future health() async {
    await dio.get('${Environment.baseApiUrl}/health');
  }
}

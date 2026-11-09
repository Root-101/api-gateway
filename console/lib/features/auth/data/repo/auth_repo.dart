import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepo {
  static final String tokenKey = 'credentials.token';
  //"remember me" stored these before 6.0.0, they are removed so the password doesn't stay in the browser
  static final String legacyUsernameKey = 'credentials.username';
  static final String legacyPasswordKey = 'credentials.password';

  final AuthClient client;
  final FlutterSecureStorage storage;

  AuthRepo({required this.client, required this.storage});

  Future<String> login({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final token = await client.login(username: username, password: password);

      if (rememberMe) {
        await storage.write(key: tokenKey, value: token);
      }
      return token;
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  ///any error (network, CORS, 503) means the console can't use the gateway right now
  Future<bool> isGatewayUp() async {
    try {
      await client.health();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future logout() async {
    await storage.delete(key: tokenKey);
  }

  ///not validated here: an expired or revoked token gets a 401 on the first call, which logs out
  Future<String?> loadCache() async {
    try {
      await storage.delete(key: legacyUsernameKey);
      await storage.delete(key: legacyPasswordKey);

      final token = await storage.read(key: tokenKey);
      if (token != null && token.isNotEmpty) {
        return token;
      }
    } on Exception {
      app.logger.e('Error loading token from cache');
      await storage.deleteAll();
    }
    return null;
  }
}

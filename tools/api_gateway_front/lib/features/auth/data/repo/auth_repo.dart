import 'dart:convert';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepo {
  static final String credentialUsernameKey = 'api-wallet.credentials.username';
  static final String credentialPasswordKey = 'api-wallet.credentials.password';

  final AuthClient client;
  final FlutterSecureStorage storage;

  AuthRepo({required this.client, required this.storage});

  Future login({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      await client.login(username: username, password: password);

      String encodedUsername = base64Encode(utf8.encode(username));
      String encodedPassword = base64Encode(utf8.encode(password));

      print('************************');
      print(encodedUsername);
      print(encodedPassword);

      if (rememberMe) {
        await storage.write(key: credentialUsernameKey, value: encodedUsername);
        await storage.write(key: credentialPasswordKey, value: encodedPassword);
      }
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future logout() async {
    await storage.delete(key: credentialUsernameKey);
    await storage.delete(key: credentialPasswordKey);
  }

  Future<({String username, String password})?> loadCache() async {
    try {
      String? cacheRawUsername = await storage.read(key: credentialUsernameKey);
      String? cacheRawPassword = await storage.read(key: credentialPasswordKey);
      print('--------------------------------');
      print(cacheRawUsername);
      print(cacheRawPassword);
      if (cacheRawUsername != null &&
          cacheRawUsername.isNotEmpty &&
          cacheRawPassword != null &&
          cacheRawPassword.isNotEmpty) {
        String cacheUsername = utf8.decode(base64Decode(cacheRawUsername));
        String cachePassword = utf8.decode(base64Decode(cacheRawPassword));

        return (username: cacheUsername, password: cachePassword);
      }
    } on Exception catch (exc) {
      app.logger.e('Error loading credential from cache');
      await storage.deleteAll();
    }
    return null;
  }
}

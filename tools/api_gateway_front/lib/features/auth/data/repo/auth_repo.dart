import 'package:api_gateway_front/app_exporter.dart';

class AuthRepo {
  final AuthClient client;

  AuthRepo({required this.client});

  Future login({required String username, required String password}) async {
    try {
      await client.login(username: username, password: password);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }
}

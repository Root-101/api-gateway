import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

///every request answers 200 with [body]
AuthClient clientAnswering(dynamic body) {
  final dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: body),
        ),
      ),
    );
  return AuthClient(dio);
}

void main() {
  const storage = FlutterSecureStorage();
  final tokenBody = {'token': 'abc', 'expires_in': 28800};

  AuthRepo repo(dynamic body) =>
      AuthRepo(client: clientAnswering(body), storage: storage);

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('requests are sent with the bearer token', () {
    final headers = clientAnswering(
      null,
    ).options(credential: CredentialsModel(token: 'abc')).headers;
    expect(headers?['authorization'], 'Bearer abc');
  });

  test('remember me stores only the token and it is loaded back', () async {
    final token = await repo(
      tokenBody,
    ).login(username: 'u', password: 'p', rememberMe: true);

    expect(token, 'abc');
    expect(await storage.readAll(), {AuthRepo.tokenKey: 'abc'});
    expect(await repo(tokenBody).loadCache(), 'abc');
  });

  test('without remember me nothing is stored', () async {
    await repo(
      tokenBody,
    ).login(username: 'u', password: 'p', rememberMe: false);

    expect(await storage.readAll(), isEmpty);
  });

  test('a password stored by an older version is removed', () async {
    FlutterSecureStorage.setMockInitialValues({
      AuthRepo.legacyUsernameKey: 'dQ==',
      AuthRepo.legacyPasswordKey: 'cA==',
    });

    expect(await repo(tokenBody).loadCache(), isNull);
    expect(await storage.readAll(), isEmpty);
  });

  test('a 200 without token is an error, not a session', () async {
    await expectLater(
      repo('').login(username: 'u', password: 'p', rememberMe: true),
      throwsA(isA<GlobalException>()),
    );
    expect(await storage.readAll(), isEmpty);
  });
}

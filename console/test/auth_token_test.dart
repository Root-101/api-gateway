import 'package:console/app_exporter.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  final tokenBody = {'token': 'abc', 'expires_in': 28800};

  AuthRepo repo(dynamic body) =>
      AuthRepo(client: clientAnswering(body), storage: storage);

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('AuthInterceptor', () {
    AuthCubit cubit() => AuthCubit(repo: repo(tokenBody));

    Future<AuthCubit> loggedIn() async {
      final auth = cubit();
      await auth.login(username: 'u', password: 'p', rememberMe: false);
      return auth;
    }

    ///answers every request with [status] and records what was sent
    Dio dioAnswering(
      AuthCubit auth,
      int status, [
      List<RequestOptions>? sent,
    ]) => Dio()
      ..interceptors.addAll([
        AuthInterceptor(auth),
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent?.add(options);
            final response = Response(
              requestOptions: options,
              statusCode: status,
            );
            status == 200
                ? handler.resolve(response)
                : handler.reject(
                    DioException.badResponse(
                      statusCode: status,
                      requestOptions: options,
                      response: response,
                    ),
                    true,
                  );
          },
        ),
      ]);

    test('requests carry the bearer token of the session', () async {
      final sent = <RequestOptions>[];
      await dioAnswering(await loggedIn(), 200, sent).get('http://x/routes');
      expect(sent.single.headers['authorization'], 'Bearer abc');
    });

    test('without a session no header is sent', () async {
      final sent = <RequestOptions>[];
      await dioAnswering(cubit(), 200, sent).get('http://x/health');
      expect(sent.single.headers.containsKey('authorization'), isFalse);
    });

    test('parallel 401s log out only once', () async {
      final auth = await loggedIn();
      final logouts = <AuthState>[];
      final subscription = auth.stream
          .where((state) => state is AuthLogoutOkState)
          .listen(logouts.add);
      final dio = dioAnswering(auth, 401);

      await Future.wait([
        for (var i = 0; i < 3; i++)
          dio
              .get('http://x/routes')
              .catchError((_) => Response(requestOptions: RequestOptions())),
      ]);
      await pumpEventQueue();

      expect(auth.isLoggedIn, isFalse);
      expect(logouts, hasLength(1));
      await subscription.cancel();
    });

    test('a 401 without a session does not log out', () async {
      final auth = cubit();
      final states = <AuthState>[];
      final subscription = auth.stream.listen(states.add);

      await expectLater(
        dioAnswering(auth, 401).post('http://x/login'),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();

      expect(states, isEmpty);
      await subscription.cancel();
    });
  });

  test('remember me stores only the token and it is loaded back', () async {
    final token = await repo(tokenBody)
        .login(username: 'u', password: 'p', rememberMe: true);

    expect(token, 'abc');
    expect(await storage.readAll(), {AuthRepo.tokenKey: 'abc'});
    expect(await repo(tokenBody).loadCache(), 'abc');
  });

  test('without remember me nothing is stored', () async {
    await repo(tokenBody)
        .login(username: 'u', password: 'p', rememberMe: false);

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

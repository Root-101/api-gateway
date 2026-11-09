import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final AuthCubit auth;

  AuthInterceptor(this.auth);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = auth.token;
    if (token != null) {
      options.headers['authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  ///any rejected credential on any admin call ends the session (routes, logs, form, restore, export)
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final status = error.response?.statusCode;
    //not logged in = login screen, which handles its own errors
    if ((status == 401 || status == 403) && auth.isLoggedIn) {
      auth.logout();
    }
    handler.next(error);
  }
}

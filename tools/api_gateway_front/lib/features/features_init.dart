import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FeaturesInit {
  static Future<void> init() async {
    FlutterSecureStorage storage = const FlutterSecureStorage(
      webOptions: WebOptions(publicKey: 'api-gateway'),
    );
    app.di.put(storage);

    Dio dio = Dio();
    dio
      ..options.connectTimeout = const Duration(seconds: 10)
      ..options.receiveTimeout = const Duration(seconds: 10)
      ..httpClientAdapter
      ..options.headers = {
        Headers.contentTypeHeader: Headers.jsonContentType,
      };
    //any rejected credential on any admin call ends the session (routes, logs, form, restore, export)
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final status = error.response?.statusCode;
          final auth = app.di.find<AuthCubit>();
          //not logged in = login screen or cached-login check, which handle their own errors
          if ((status == 401 || status == 403) && auth.isLoggedIn) {
            auth.logout();
          }
          handler.next(error);
        },
      ),
    );
    app.di.put(dio);

    await AuthInit.init();
    final sessionTimeout = Environment.sessionTimeout;
    if (sessionTimeout != null) {
      InactivityLogout.start(
        auth: app.di.find<AuthCubit>(),
        timeout: sessionTimeout,
      );
    }
    //on logout: reset every cubit and go to login (single subscription, lives as long as the app)
    app.di.find<AuthCubit>().stream.listen((event) {
      if (event is AuthLogoutOkState) {
        FeaturesInit.reset();
        LoginScreen.navigator.neglectGo();
      }
    });
    await LanguageInit.init();
    await RoutesInit.init(); //logs need routes for filter

    await Future.wait([LogsInit.init()]);
  }

  static Future<void> reset() async {
    app.di.find<AuthCubit>().reset();
    app.di.find<RoutesCubit>().reset();
    app.di.find<LogsCubit>().reset();
  }

  static List<BlocProvider> blocProviders = [
    //AUTH
    BlocProvider<AuthCubit>(create: (context) => app.di.find<AuthCubit>()),
    //ROUTES
    BlocProvider<RoutesCubit>(create: (context) => app.di.find<RoutesCubit>()),
    //LOGS
    BlocProvider<LogsCubit>(create: (context) => app.di.find<LogsCubit>()),
    //LANGUAGE
    BlocProvider<LanguageCubit>(
      create: (context) => app.di.find<LanguageCubit>(),
    ),
  ];
}

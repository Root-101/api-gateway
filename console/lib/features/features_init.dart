import 'package:console/app_exporter.dart';
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
      ..options.headers = {Headers.contentTypeHeader: Headers.jsonContentType};
    app.di.put(dio);

    await AuthInit.init();
    final auth = app.di.find<AuthCubit>();
    final gatewayStatus = GatewayStatusCubit(ping: auth.isGatewayUp);
    app.di.put(gatewayStatus);
    dio.interceptors.addAll([
      LanguageHeaderInterceptor(
        languageCode: () => AppIntl.current.languageCode,
      ),
      AuthInterceptor(auth),
      GatewayStatusInterceptor(status: gatewayStatus, auth: auth),
    ]);
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
        _resetCubits();
        LoginScreen.navigator.neglectGo();
        app.toast.success(app.intl.login.signedOut);
      } else if (event is AuthSessionExpiredState) {
        SessionExpiredDialog.navigator.open();
      }
    });
    await LanguageInit.init();
    await RoutesInit.init(); //logs need routes for filter

    await Future.wait([LogsInit.init()]);
  }

  /// Every singleton cubit but the language, which survives the logout
  static Future<void> _resetCubits() async {
    app.di.find<AuthCubit>().reset();
    app.di.find<GatewayStatusCubit>().reset();
    app.di.find<RoutesCubit>().reset();
    app.di.find<MaintenanceCubit>().reset();
    app.di.find<HealthCheckCubit>().reset();
    app.di.find<RateLimitCubit>().reset();
    app.di.find<CorsCubit>().reset();
    app.di.find<LogsCubit>().reset();
  }

  static List<BlocProvider> blocProviders = [
    //AUTH
    BlocProvider<AuthCubit>(create: (context) => app.di.find<AuthCubit>()),
    //GATEWAY STATUS
    BlocProvider<GatewayStatusCubit>(
      create: (context) => app.di.find<GatewayStatusCubit>(),
    ),
    //LANGUAGE
    BlocProvider<LanguageCubit>(
      create: (context) => app.di.find<LanguageCubit>(),
    ),
    //ROUTES
    BlocProvider<RoutesCubit>(create: (context) => app.di.find<RoutesCubit>()),
    BlocProvider<MaintenanceCubit>(
      create: (context) => app.di.find<MaintenanceCubit>(),
    ),
    BlocProvider<HealthCheckCubit>(
      create: (context) => app.di.find<HealthCheckCubit>(),
    ),
    BlocProvider<RateLimitCubit>(
      create: (context) => app.di.find<RateLimitCubit>(),
    ),
    BlocProvider<CorsCubit>(create: (context) => app.di.find<CorsCubit>()),
    //LOGS
    BlocProvider<LogsCubit>(create: (context) => app.di.find<LogsCubit>()),
  ];
}

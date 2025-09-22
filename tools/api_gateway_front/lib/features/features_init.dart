import 'dart:io';

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
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      };
    app.di.put(dio);

    await AuthInit.init();
    //once the auth is initialized, I subscribe to listen to logout changes to reset cubits
    app.di.find<AuthCubit>().stream.listen((event) {
      if (event is AuthLogoutOkState) {
        FeaturesInit.reset();
      }
    });
    await LanguageInit.init();
    await RoutesInit.init(); //logs need routes for filter

    await Future.wait([LogsInit.init()]);

    //prepare logout
    app.di.find<AuthCubit>().stream.listen((event) {
      if (event is AuthLogoutOkState) {
        LoginScreen.navigator.neglectGo();
      }
    });
  }

  static Future<void> reset() async {
    app.di.find<AuthCubit>().reset();
    app.di.find<RoutesCubit>().reset();
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

import 'dart:io';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeaturesInit {
  static Future<void> init() async {
    final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    app.di.put(sharedPrefs);

    Dio dio = Dio();
    dio
      ..options.connectTimeout = const Duration(seconds: 10)
      ..options.receiveTimeout = const Duration(seconds: 10)
      ..httpClientAdapter
      ..options.headers = {
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
        /*'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': '*',*/
      };
    app.di.put(dio);

    await initLocalStorage();
    app.di.put(localStorage);

    await AuthInit.init();
    //once the auth is initialized, I subscribe to listen to logout changes and reser cubits
    app.di.find<AuthCubit>().stream.listen((event) {
      if (event is AuthLogoutOkState) {
        FeaturesInit.reset();
      }
    });
    await LanguageInit.init();

    await Future.wait([RoutesInit.init(), LogsInit.init()]);

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

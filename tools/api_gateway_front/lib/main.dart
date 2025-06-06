import 'dart:ui';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Init {
  Init._();

  static final instance = Init._();

  Future initialize() async {
    ///para que salga el splash, si no es muy rapido
    await Future.delayed(const Duration(seconds: 1));

    await FeaturesInit.init();
  }
}

void main() {
  ///add this option so the .push method ono go-router can override url
  GoRouter.optionURLReflectsImperativeAPIs = true;

  WidgetsFlutterBinding.ensureInitialized();

  //manejo de errores
  FlutterError.onError = (errorDetails) {
    app.logger.e('------------------- error 1 -------------------');
    app.logger.e(errorDetails.exception);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    app.logger.e('------------------- error 2 -------------------');
    app.logger.e(error);
    app.logger.e(stack);
    return true;
  };

  runApp(
    FutureBuilder(
      future: Init.instance.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiBlocProvider(
            providers: [...FeaturesInit.blocProviders],
            child: const App(),
          );
        } else {
          return const SplashScreen();
        }
      },
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay.buildGlobal(
      child: LanguageListener(
        onLanguageChangeBuilder: (locale) {
          Size size = MediaQuery.of(context).size;
          if (size.width < 800 || size.height < 400) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeConfig.theme,
              locale: locale,
              builder:
                  (context, child) => const Scaffold(
                    body: Center(child: Text('Need more space')),
                  ),
            );
          } else {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Api-Gateway',
              theme: ThemeConfig.theme,
              locale: locale,
              routerConfig: RouteConfig.router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            );
          }
        },
      ),
    );
  }
}

AppGlobal app = AppGlobal();

class AppGlobal {
  static final AppGlobal _instance = AppGlobal._internal();

  AppGlobal._internal();

  factory AppGlobal() => _instance;

  BuildContext get context => navigatorKey.currentContext!;

  ThemeData get theme => Theme.of(context);

  TextTheme get textTheme => theme.textTheme;

  AppLocalizations get intl => context.intl;

  Logger logger = Logger();

  LoadingOverlay loading = LoadingOverlay();

  DI di = DI();

  NavigatorHelper navigator = NavigatorHelper();

  AppDimensions dimensions = AppDimensions();

  AppColors colors = AppColors();

  AppAssets assets = AppAssets();

  DateFormatter dateFormatter = DateFormatter();

  SnackBarAdapter snack = SnackBarAdapter();

  DialogHelper dialog = DialogHelper();

  MediaQueryData get mediaQuery => MediaQuery.of(context);
}

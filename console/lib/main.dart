import 'dart:js_interop';
import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

@JS('removeSplashFromWeb')
external void _removeWebSplash();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// The Material texts (date picker, tooltips...); the app's own come from `context.intl` (slang)
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    GlobalMaterialLocalizations.delegates;

//generate code
//fvm flutter pub run build_runner build --delete-conflicting-outputs
//fvm dart run slang

//versions
//fvm flutter pub outdated
//fvm flutter pub upgrade --major-versions
class Init {
  Init._();

  static final instance = Init._();

  Future initialize() async {
    await FeaturesInit.init();
  }
}

void main() {
  ///add this option so the .push method ono go-router can override url
  GoRouter.optionURLReflectsImperativeAPIs = true;

  WidgetsFlutterBinding.ensureInitialized();
  RouteConfig.launchLocation = PlatformDispatcher.instance.defaultRouteName;
  //the html splash (web/index.html) covers the download of the app; Flutter's SplashScreen looks the same
  WidgetsBinding.instance.addPostFrameCallback((_) => _removeWebSplash());

  //error handling
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

  //a broken env.js used to fail silently; show the operator what is wrong (no intl yet, plain text)
  final configError = Environment.configError;
  if (configError != null) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: SelectableText('Configuration error: $configError'),
          ),
        ),
      ),
    );
    return;
  }

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
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: appSupportedLocales,
              builder: (context, child) => Scaffold(
                body: Center(child: Text(context.intl.app.needMoreSpace)),
              ),
            );
          } else {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) => context.intl.app.name,
              theme: ThemeConfig.theme,
              locale: locale,
              routerConfig: RouteConfig.router,
              builder: (context, child) => ToastHost(child: child!),
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: appSupportedLocales,
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

  /// Texts of the app's language; without a navigator yet (or in unit tests) the base ones (`en`).
  /// The caller does not rebuild on a language change: use `context.intl` for what is on screen behind the selector
  AppMessages get intl {
    final context = navigatorKey.currentContext;
    return context != null ? context.intl : messagesOf(const Locale('en'));
  }

  //the default filter is silent in release builds, where errors must still reach the console
  Logger logger = Logger(filter: ProductionFilter(), level: Level.warning);

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

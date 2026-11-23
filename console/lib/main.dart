import 'dart:js_interop';
import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

@JS('removeSplashFromWeb')
external void _removeWebSplash();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  //until LanguageCubit loads the saved one: the browser's language (an unknown one: English)
  AppIntl.current = AppIntl.resolve(PlatformDispatcher.instance.locale.languageCode);
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
    return LanguageListener(
      onLanguageChangeBuilder: (locale) {
        Size size = MediaQuery.of(context).size;
        if (size.width < 800 || size.height < 400) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: locale,
            localizationsDelegates: AppIntl.delegates,
            supportedLocales: AppIntl.supportedLocales,
            builder: (context, child) => Scaffold(
              body: Center(child: Text(context.intl.app.needMoreSpace)),
            ),
          );
        } else {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.intl.app.name,
            theme: AppTheme.dark,
            locale: locale,
            routerConfig: RouteConfig.router,
            builder: (context, child) => ToastHost(child: child!),
            localizationsDelegates: AppIntl.delegates,
            supportedLocales: AppIntl.supportedLocales,
          );
        }
      },
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

  /// Texts of the current language (`AppIntl`); widgets use `context.intl` to rebuild on a language change
  AppTexts get intl => AppIntl.texts;

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

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class RouteConfig {
  ///the url the page was opened with, read in `main` before the splash's navigator resets it to `/` (F5 on a deep link)
  static String launchLocation = '/';

  static RouterConfig<Object> router = GoRouter(
    initialLocation: app.di.find<AuthCubit>().isLoggedIn
        ? (launchLocation != '/'
              ? launchLocation
              : GatewayMapScreen.navigator.path)
        : LoginScreen.navigator.path,
    navigatorKey: navigatorKey,
    //guard: logged-out users only see login, logged-in users never see it
    refreshListenable: _AuthRefresh(app.di.find<AuthCubit>().stream),
    redirect: (context, state) {
      final loggedIn = app.di.find<AuthCubit>().isLoggedIn;
      final atLogin = state.matchedLocation == LoginScreen.navigator.path;
      if (!loggedIn && !atLogin) return LoginScreen.navigator.path;
      if (loggedIn && atLogin) return GatewayMapScreen.navigator.path;
      return null;
    },
    //unknown url: 404 inside the shell (the guard sends it to login when logged out)
    onException: (context, state, router) =>
        router.go(NotFoundScreen.navigator.location(state.uri.toString())),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BaseScreen(navigationShell);
        },
        branches: [
          ///   /map (start screen)
          StatefulShellBranch(routes: GatewayMapScreen.navigator.routes()),

          ///   /routes, /routes/:id/edit
          StatefulShellBranch(
            routes: RoutesScreen.navigator.routes(
              children: RoutesFormScreen.navigator.routes(),
            ),
          ),

          ///   /logs
          StatefulShellBranch(routes: LogsScreen.navigator.routes()),

          ///   /not-found
          StatefulShellBranch(routes: NotFoundScreen.navigator.routes()),
        ],
      ),
      //---------------- LOGIN ----------------\\
      ...LoginScreen.navigator.routes(),
    ],
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    stream.listen((_) => notifyListeners());
  }
}

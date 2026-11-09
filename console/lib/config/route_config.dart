import 'package:api_gateway_front/app_exporter.dart';
import 'package:api_gateway_front/features/routes/view/form/routes_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteConfig {
  static RouterConfig<Object> router = GoRouter(
    initialLocation: app.di.find<AuthCubit>().isLoggedIn
        ? RoutesScreen.navigator.path
        : LoginScreen.navigator.path,
    navigatorKey: navigatorKey,
    //guard: logged-out users only see login, logged-in users never see it
    refreshListenable: _AuthRefresh(app.di.find<AuthCubit>().stream),
    redirect: (context, state) {
      final loggedIn = app.di.find<AuthCubit>().isLoggedIn;
      final atLogin = state.matchedLocation == LoginScreen.navigator.path;
      if (!loggedIn && !atLogin) return LoginScreen.navigator.path;
      if (loggedIn && atLogin) return RoutesScreen.navigator.path;
      return null;
    },
    //unknown url: go home (the guard sends it to login when logged out)
    onException: (context, state, router) =>
        router.go(RoutesScreen.navigator.path),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BaseScreen(navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: <RouteBase>[
              ///   /routes
              GoRoute(
                name: RoutesScreen.navigator.name,
                path: RoutesScreen.navigator.path,
                builder: RoutesScreen.navigator.builder,
                routes: [
                  ///   /routes/:id/edit (dialog over the whole app, so on the root navigator)
                  GoRoute(
                    name: RoutesFormScreen.navigator.editName,
                    path: RoutesFormScreen.navigator.editPath,
                    parentNavigatorKey: navigatorKey,
                    pageBuilder: RoutesFormScreen.navigator.editPageBuilder,
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              ///   /logs
              GoRoute(
                name: LogsScreen.navigator.name,
                path: LogsScreen.navigator.path,
                builder: LogsScreen.navigator.builder,
              ),
            ],
          ),
        ],
      ),
      //---------------- LOGIN ----------------\\
      GoRoute(
        name: LoginScreen.navigator.name,
        path: LoginScreen.navigator.path,
        builder: LoginScreen.navigator.builder,
      ),
    ],
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    stream.listen((_) => notifyListeners());
  }
}

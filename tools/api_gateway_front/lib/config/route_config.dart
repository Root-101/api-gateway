import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteConfig {
  static RouterConfig<Object> router = GoRouter(
    initialLocation:
        app.di.find<AuthCubit>().isLoggedIn
            ? RoutesScreen.navigator.path
            : LoginScreen.navigator.path,
    navigatorKey: navigatorKey,
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

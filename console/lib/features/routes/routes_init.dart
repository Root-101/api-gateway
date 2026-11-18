import 'package:console/app_exporter.dart';

class RoutesInit {
  static Future<void> init() async {
    RoutesClient client = RoutesClient(app.di.find());
    app.di.put(client);

    RoutesRepo repo = RoutesRepo(client: client);
    app.di.put(repo);

    RoutesCubit cubit = RoutesCubit(repo: repo);
    app.di.put(cubit);

    app.di.put(MaintenanceCubit(repo: repo));
    app.di.put(HealthCheckCubit(repo: repo));
    app.di.put(RateLimitCubit(repo: repo));
  }
}

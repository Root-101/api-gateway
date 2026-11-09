import 'package:api_gateway_front/app_exporter.dart';

class RoutesInit {
  static Future<void> init() async {
    RoutesClient client = RoutesClient(app.di.find());
    app.di.put(client);

    RoutesRepo repo = RoutesRepo(client: client);
    app.di.put(repo);

    RoutesCubit cubit = RoutesCubit(repo: repo, auth: app.di.find());
    app.di.put(cubit);
  }
}

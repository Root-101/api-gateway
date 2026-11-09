import 'package:api_gateway_front/app_exporter.dart';

class LogsInit {
  static Future<void> init() async {
    LogsClient client = LogsClient(app.di.find());
    app.di.put(client);

    LogsRepo repo = LogsRepo(client: client);
    app.di.put(repo);

    LogsCubit cubit = LogsCubit(
      auth: app.di.find(),
      repo: repo,
      routesRepo: app.di.find(),
    );
    app.di.put(cubit);
  }
}

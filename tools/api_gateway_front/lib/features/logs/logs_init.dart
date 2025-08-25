import 'package:api_gateway_front/app_exporter.dart';

class LogsInit {
  static Future<void> init() async {
    LogsCubit cubit = LogsCubit(auth: app.di.find());
    app.di.put(cubit);
  }
}

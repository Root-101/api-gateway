import 'package:api_gateway_front/app_exporter.dart';

class LanguageInit {
  static Future<void> init() async {
    LanguageRepo repo = LanguageRepo(prefs: app.di.find());
    app.di.put(repo);

    LanguageCubit cubit = LanguageCubit(repo: repo);
    app.di.put(cubit);
  }
}

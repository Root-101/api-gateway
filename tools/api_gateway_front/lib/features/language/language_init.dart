import 'package:api_gateway_front/app_exporter.dart';

class LanguageInit {
  static Future<void> init() async {
    LanguageRepo repo = LanguageRepo(storage: app.di.find());
    app.di.put(repo);

    LanguageCubit cubit = LanguageCubit(repo: repo);
    //awaited so the saved language is applied before the first frame (no flicker)
    await cubit.init();
    app.di.put(cubit);
  }
}

import 'package:api_gateway_front/app_exporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageRepo {
  SharedPreferences prefs;

  final String _languageStorageKey = 'api-gateway.cache.language';

  LanguageRepo({required this.prefs});

  void save({required LanguageModel model}) {
    prefs.setString(_languageStorageKey, model.key);
  }

  String? loadKey() {
    return prefs.getString(_languageStorageKey);
  }
}

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageRepo {
  static final String languageKey = 'language.key';
  final FlutterSecureStorage storage;

  LanguageRepo({required this.storage});

  Future save({required LanguageModel model}) async {
    await storage.write(key: languageKey, value: model.key);
  }

  Future<String?> loadKey() async {
    return storage.read(key: languageKey);
  }
}

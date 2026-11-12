import 'package:dio/dio.dart';

///`flutter build web` writes version.json from pubspec.yaml: no extra dependency, loaded once
final Future<String?> appVersion = Dio()
    .get(Uri.base.resolve('version.json').toString())
    .then((r) => (r.data is Map ? r.data['version'] : null)?.toString())
    .catchError((_) => null);

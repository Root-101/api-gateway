import 'dart:convert';

import 'package:dio/dio.dart';

///`flutter build web` writes version.json from pubspec.yaml: no extra dependency, loaded once.
///Read as text: `flutter run` serves it as javascript, so Dio wouldn't parse it as a map
final Future<String?> appVersion = Dio()
    .get<String>(
      Uri.base.resolve('version.json').toString(),
      options: Options(responseType: ResponseType.plain),
    )
    .then((r) {
      final json = jsonDecode(r.data ?? '');
      return (json is Map ? json['version'] : null)?.toString();
    })
    .catchError((_) => null);

import 'package:dio/dio.dart';

/// Sends the console's language on every request (`Accept-Language`): the gateway answers its error texts (`detail`,
/// the 422's items) in it. It knows `en` and `es`; anything else gets English
class LanguageHeaderInterceptor extends Interceptor {
  /// The current language code (`es`, `en`), read on every request
  final String Function() languageCode;

  LanguageHeaderInterceptor({required this.languageCode});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = languageCode();
    handler.next(options);
  }
}

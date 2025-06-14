import 'dart:js_interop';

@JS('window.env')
external EnvConfig get env;

@JS()
@staticInterop
class EnvConfig {}

extension EnvConfigExtension on EnvConfig {
  external String get GATEWAY_SERVICE_URL;

  external String get ADMIN_PATH;
}

///use it like this
class Environment {
  static String get gatewayUrl => 'https://${env.GATEWAY_SERVICE_URL}';

  static String get baseApiUrl =>
      'https://${env.GATEWAY_SERVICE_URL}/${env.ADMIN_PATH}';

  static Map<String, String> get raw => {
    'GATEWAY_SERVICE_URL': env.GATEWAY_SERVICE_URL,
    'ADMIN_PATH': env.ADMIN_PATH,
  };
}

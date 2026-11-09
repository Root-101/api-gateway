import 'dart:js_interop';

//null when env.js is missing or doesn't define window.env
@JS('window.env')
external EnvConfig? get env;

@JS()
@staticInterop
class EnvConfig {}

extension EnvConfigExtension on EnvConfig {
  //nullable: a missing field is `undefined` in JS
  external String? get GATEWAY_SERVICE_URL;

  external String? get ADMIN_PATH;

  //optional, may be missing in old env.js files; number or numeric string
  external JSAny? get SESSION_TIMEOUT_MINUTES;
}

///use it like this
class Environment {
  ///human readable problem with env.js, null when it is usable
  static String? get configError {
    if (env == null) return 'env.js is missing or does not define window.env';
    final missing = [
      if ((env!.GATEWAY_SERVICE_URL ?? '').trim().isEmpty)
        'GATEWAY_SERVICE_URL',
      if ((env!.ADMIN_PATH ?? '').trim().isEmpty) 'ADMIN_PATH',
    ];
    return missing.isEmpty ? null : 'env.js: missing ${missing.join(', ')}';
  }

  ///null = no inactivity logout (missing, 0, or not a number)
  static Duration? get sessionTimeout {
    final minutes = num.tryParse(
      env?.SESSION_TIMEOUT_MINUTES?.dartify()?.toString() ?? '',
    );
    return minutes == null || minutes <= 0
        ? null
        : Duration(seconds: (minutes * 60).round());
  }

  ///without trailing `/`, `https://` added when there is no scheme
  static String get gatewayUrl {
    final url = (env?.GATEWAY_SERVICE_URL ?? '').trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    return url.startsWith('http') ? url : 'https://$url';
  }

  ///without leading/trailing `/`
  static String get adminPath =>
      (env?.ADMIN_PATH ?? '').trim().replaceAll(RegExp(r'^/+|/+$'), '');

  static String get baseApiUrl => '$gatewayUrl/$adminPath';

  static Map<String, String> get raw => {
    'GATEWAY_SERVICE_URL': env?.GATEWAY_SERVICE_URL ?? '',
    'ADMIN_PATH': env?.ADMIN_PATH ?? '',
    'gatewayUrl': gatewayUrl,
    'baseApiUrl': baseApiUrl,
  };
}

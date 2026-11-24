///CORS add-on of a route or of the whole gateway: which browser origins may call it, and (routes
///only) whether they may send cookies. The gateway's is always there, can't be turned off and has
///no credentials; a route without its own, or with it off, uses the gateway's
class CorsModel {
  final bool enabled;

  ///`https://app.com`, `https://*.example.com` or `*`; at least one
  final List<String> allowedOrigins;
  final bool allowCredentials;

  ///gateway only, read-only: `CORS_ALLOWED_ORIGINS` when it's set (deprecated, gone in 7.0)
  final CorsEnvVar? envVar;

  CorsModel({
    required this.enabled,
    required this.allowedOrigins,
    this.allowCredentials = false,
    this.envVar,
  });

  CorsModel copyWith({bool? enabled}) => CorsModel(
    enabled: enabled ?? this.enabled,
    allowedOrigins: allowedOrigins,
    allowCredentials: allowCredentials,
    envVar: envVar,
  );
}

///the deprecated env var the gateway's CORS was seeded from; read at startup only, so it stays
///until it's removed from the deploy and the gateway restarts
class CorsEnvVar {
  final String name;
  final List<String> origins;

  ///same origins as the add-on (any order): migrated; false: set but ignored
  final bool matches;

  CorsEnvVar({
    required this.name,
    required this.origins,
    required this.matches,
  });
}

///`*`, or `scheme://host[:port]` with `*` wildcards and no path: what the api accepts. Checked on
///Enter so a bad origin never becomes a chip; the api's 422 still has the last word
bool corsOriginValid(String origin) => RegExp(
  r'^(\*|[a-z][a-z0-9+.-]*://[^/\s]+)$',
  caseSensitive: false,
).hasMatch(origin);

///a pattern that lets every origin in (`*`, `https://*`...): the badge says `ALL`
bool corsAllowsAll(String pattern) =>
    pattern == '*' ||
    RegExp(r'^[a-z]+://\*(:(\*|\[\*\]|\d+))?$').hasMatch(pattern);

///a pattern that lets any site in: `*`, or a `*` in the host other than `*.domain.com`. The api
///rejects it with credentials (twin of the gateway's `Cors.allowsAnyOrigin`)
bool corsAllowsAnySite(String pattern) {
  final host = pattern
      .replaceFirst(RegExp(r'^[^:]*://'), '')
      .replaceFirst(RegExp(r':(\[[^\]]*\]|[^:\]]*)$'), '');
  return pattern == '*' ||
      host.contains('*') && !RegExp(r'^\*\.[^*]+\.[^*]+$').hasMatch(host);
}

///whether [origin] (`https://console.app.com`) passes [patterns], to warn before the gateway's
///own CORS locks this console out.
///shortcut: `*` matches any run of characters, as Spring's origin patterns roughly do; the api's
///400 is the real check, this only warns
bool corsAllows(List<String> patterns, String origin) => patterns.any((p) {
  if (p == '*') return true;
  //`:[*]` is any port or none
  final regex = p
      .split(':[*]')
      .map((part) => part.split('*').map(RegExp.escape).join('.*'))
      .join(r'(:\d+)?');
  return RegExp('^$regex\$', caseSensitive: false).hasMatch(origin);
});

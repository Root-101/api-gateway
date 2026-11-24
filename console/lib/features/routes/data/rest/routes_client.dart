import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class RoutesClient extends BaseClient {
  @override
  String get baseUrl => '${Environment.baseApiUrl}/routes';

  RoutesClient(super.dio);

  Future<List<RouteResponse>> list() async {
    Response rawResponse = await dio.get(baseUrl);

    return rawResponse.data!
        .map((dynamic i) => RouteResponse.fromJson(i as Map<String, dynamic>))
        .toList()
        .cast<RouteResponse>();
  }

  ///same rules as create and edit, nothing saved: 204 or a 422 with the broken fields
  Future validate({required RouteRequest model}) async {
    await dio.post('$baseUrl/validate', data: model.toJson());
  }

  Future create({required RouteRequest model}) async {
    await dio.post(baseUrl, data: model.toJson());
  }

  ///atomic: every current route is replaced by [models], or nothing changes
  Future replaceAll({required List<RouteRequest> models}) async {
    await dio.put(baseUrl, data: models.map((e) => e.toJson()).toList());
  }

  Future edit({required String routeId, required RouteRequest model}) async {
    await dio.put('$baseUrl/$routeId', data: model.toJson());
  }

  Future delete({required String routeId}) async {
    await dio.delete('$baseUrl/$routeId');
  }

  Future<RouteResponse> details({required String routeId}) async {
    Response rawResponse = await dio.get('$baseUrl/$routeId');
    return RouteResponse.fromJson(rawResponse.data! as Map<String, dynamic>);
  }

  ///add-ons of a route, or of the gateway when [routeId] is null
  String _addons(String? routeId) => routeId == null
      ? '${Environment.baseApiUrl}/addons'
      : '$baseUrl/$routeId/addons';

  ///the gateway's add-ons (`maintenance`, `rate_limit`, `cors`: null = not configured)
  Future<GatewayAddonsResponse> gatewayAddons() async {
    Response rawResponse = await dio.get(_addons(null));
    final data = rawResponse.data;
    return GatewayAddonsResponse.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  ///creates or replaces it: 200 with the saved object; 404 when the route doesn't exist, 422 when invalid
  Future<MaintenanceResponse> putMaintenance({
    required MaintenanceRequest model,
    String? routeId,
  }) async {
    Response rawResponse = await dio.put(
      '${_addons(routeId)}/maintenance',
      data: model.toJson(),
    );
    return MaintenanceResponse.fromJson(
      rawResponse.data as Map<String, dynamic>,
    );
  }

  ///204, also when there is none; [routeId] null = the gateway's
  Future deleteMaintenance({String? routeId}) async {
    await dio.delete('${_addons(routeId)}/maintenance');
  }

  ///idempotent; 404 when it isn't configured
  Future<MaintenanceResponse> setMaintenanceEnabled({
    required bool enabled,
    String? routeId,
  }) async {
    Response rawResponse = await dio.post(
      '${_addons(routeId)}/maintenance/${enabled ? 'enable' : 'disable'}',
    );
    return MaintenanceResponse.fromJson(
      rawResponse.data as Map<String, dynamic>,
    );
  }

  ///creates or replaces it; 422 fields `enabled`, `limit`, `period`, `burst`
  Future<RateLimitResponse?> putRateLimit({
    required RateLimitRequest model,
    String? routeId,
  }) async {
    Response rawResponse = await dio.put(
      '${_addons(routeId)}/rate-limit',
      data: model.toJson(),
    );
    return RateLimitResponse.tryFromJson(rawResponse.data);
  }

  ///204, also when there is none; [routeId] null = the gateway's
  Future deleteRateLimit({String? routeId}) async {
    await dio.delete('${_addons(routeId)}/rate-limit');
  }

  ///keeps the rest; 404 when it isn't configured
  Future<RateLimitResponse?> setRateLimitEnabled({
    required bool enabled,
    String? routeId,
  }) async {
    Response rawResponse = await dio.post(
      '${_addons(routeId)}/rate-limit/${enabled ? 'enable' : 'disable'}',
    );
    return RateLimitResponse.tryFromJson(rawResponse.data);
  }

  ///creates or replaces it; 422 fields `enabled`, `allowed_origins`, `allowed_origins/i`; the
  ///rules (credentials with `*`, the gateway's off or with credentials, a console lockout) a 400
  Future<CorsResponse?> putCors({
    required CorsRequest model,
    String? routeId,
  }) async {
    Response rawResponse = await dio.put(
      '${_addons(routeId)}/cors',
      data: model.toJson(),
    );
    return CorsResponse.tryFromJson(rawResponse.data);
  }

  ///routes only (the gateway's: 405); 204, also when there is none
  Future deleteCors({required String routeId}) async {
    await dio.delete('${_addons(routeId)}/cors');
  }

  ///routes only (the gateway's: 405); keeps the rest; 404 when it isn't configured
  Future<CorsResponse?> setCorsEnabled({
    required bool enabled,
    required String routeId,
  }) async {
    Response rawResponse = await dio.post(
      '${_addons(routeId)}/cors/${enabled ? 'enable' : 'disable'}',
    );
    return CorsResponse.tryFromJson(rawResponse.data);
  }

  ///creates or replaces it (keeps the last state); 422 fields `enabled`, `path`, `interval_seconds`
  Future putHealthCheck({
    required String routeId,
    required HealthCheckRequest model,
  }) async {
    await dio.put('${_addons(routeId)}/health-check', data: model.toJson());
  }

  ///204, also when there is none
  Future deleteHealthCheck({required String routeId}) async {
    await dio.delete('${_addons(routeId)}/health-check');
  }

  ///keeps the endpoint, interval and last result; 404 when it isn't configured
  Future setHealthCheckEnabled({
    required String routeId,
    required bool enabled,
  }) async {
    await dio.post(
      '${_addons(routeId)}/health-check/${enabled ? 'enable' : 'disable'}',
    );
  }

  ///waits for the call (up to ~5 s); 404 when it isn't configured
  Future runHealthCheck({required String routeId}) async {
    await dio.post('${_addons(routeId)}/health-check/run');
  }
}

//------------------ ROUTE REQUEST ------------------\\
class RouteRequest {
  final String name;
  final String path;
  final String uri;
  //optional in the api: null = no rewrite filter
  final RewritePathRequest? rewritePath;
  final String description;

  ///only restore (PUT /routes) applies it, as it came in the backup; create, edit and validate ignore it.
  ///null = the key wasn't in the file (the route keeps its own add-ons)
  final Map<String, dynamic>? addons;

  RouteRequest({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    this.rewritePath,
    this.addons,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'uri': uri,
      'description': description,
      'rewrite_path': rewritePath?.toJson(),
      if (addons != null) 'addons': addons,
    };
  }

  ///a route of a backup file (the routes as `GET /routes` answers them)
  factory RouteRequest.fromJson(Map<String, dynamic> json) {
    final rewrite = RewritePathResponse.tryFromJson(json['rewrite_path']);
    return RouteRequest(
      name: json['name'],
      path: json['path'],
      uri: json['uri'],
      rewritePath: rewrite == null
          ? null
          : RewritePathRequest(
              replaceFrom: rewrite.replaceFrom,
              replaceTo: rewrite.replaceTo,
            ),
      description: json['description'] ?? '',
      addons: json['addons'] is Map<String, dynamic> ? json['addons'] : null,
    );
  }
}

//------------------ REWRITE PATH REQUEST ------------------\\
class RewritePathRequest {
  final String replaceFrom;
  final String replaceTo;

  RewritePathRequest({required this.replaceFrom, required this.replaceTo});

  Map<String, dynamic> toJson() {
    return {'replace_from': replaceFrom, 'replace_to': replaceTo};
  }
}

//------------------ ROUTE RESPONSE ------------------\\
class RouteResponse {
  final String id;
  final String createdAt;

  final String name;
  final String path;
  final String uri;
  final RewritePathResponse? rewritePath;
  final String description;

  ///every add-on this gateway knows, `null` the ones not configured; kept whole for the backup
  final Map<String, dynamic> addons;

  MaintenanceResponse? get maintenance =>
      MaintenanceResponse.tryFromJson(addons['maintenance']);

  HealthCheckResponse? get healthCheck =>
      HealthCheckResponse.tryFromJson(addons['health_check']);

  RateLimitResponse? get rateLimit =>
      RateLimitResponse.tryFromJson(addons['rate_limit']);

  CorsResponse? get cors => CorsResponse.tryFromJson(addons['cors']);

  RouteResponse({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    required this.id,
    required this.createdAt,
    this.rewritePath,
    this.addons = const {},
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      uri: json['uri'],
      rewritePath: RewritePathResponse.tryFromJson(json['rewrite_path']),
      description: json['description'] ?? '',
      createdAt: json['created_at'],
      addons: json['addons'] is Map<String, dynamic> ? json['addons'] : {},
    );
  }
}

//------------------ REWRITE PATH RESPONSE ------------------\\
class RewritePathResponse {
  final String replaceFrom;
  final String replaceTo;

  RewritePathResponse({required this.replaceFrom, required this.replaceTo});

  ///null when the route has no rewrite (api sends `rewrite_path: null`)
  static RewritePathResponse? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final from = json['replace_from'];
    final to = json['replace_to'];
    if (from is! String || to is! String) return null;
    return RewritePathResponse(replaceFrom: from, replaceTo: to);
  }
}

//------------------ GATEWAY ADDONS RESPONSE ------------------\\
class GatewayAddonsResponse {
  final MaintenanceResponse? maintenance;
  final RateLimitResponse? rateLimit;
  final CorsResponse? cors;

  ///a gateway that knows the rate limit add-on sends the key (`null` when not configured)
  final bool hasRateLimitKey;

  GatewayAddonsResponse({
    required this.hasRateLimitKey,
    this.maintenance,
    this.rateLimit,
    this.cors,
  });

  factory GatewayAddonsResponse.fromJson(Map<String, dynamic> json) {
    return GatewayAddonsResponse(
      maintenance: MaintenanceResponse.tryFromJson(json['maintenance']),
      rateLimit: RateLimitResponse.tryFromJson(json['rate_limit']),
      cors: CorsResponse.tryFromJson(json['cors']),
      hasRateLimitKey: json.containsKey('rate_limit'),
    );
  }
}

//------------------ MAINTENANCE REQUEST ------------------\\
///only what the admin writes: `default_message` and `state` are read-only
class MaintenanceRequest {
  final bool enabled;
  final String? message;
  //ISO-8601 with offset
  final String? retryAfter;

  MaintenanceRequest({required this.enabled, this.message, this.retryAfter});

  Map<String, dynamic> toJson() {
    return {'enabled': enabled, 'message': message, 'retry_after': retryAfter};
  }
}

//------------------ MAINTENANCE RESPONSE ------------------\\
class MaintenanceResponse {
  final bool enabled;
  final String? message;
  //ISO-8601 with offset
  final String? retryAfter;

  //read-only, written by the gateway
  final String? defaultMessage;
  final String? enabledAt;
  final String? disabledAt;

  MaintenanceResponse({
    required this.enabled,
    this.message,
    this.retryAfter,
    this.defaultMessage,
    this.enabledAt,
    this.disabledAt,
  });

  factory MaintenanceResponse.fromJson(Map<String, dynamic> json) {
    final state = json['state'];
    return MaintenanceResponse(
      enabled: json['enabled'] as bool,
      message: json['message'] as String?,
      retryAfter: json['retry_after'] as String?,
      defaultMessage: json['default_message'] as String?,
      enabledAt: state is Map ? state['enabled_at'] as String? : null,
      disabledAt: state is Map ? state['disabled_at'] as String? : null,
    );
  }

  ///null when it isn't configured (the api sends `maintenance: null`)
  static MaintenanceResponse? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic> || json['enabled'] is! bool) return null;
    return MaintenanceResponse.fromJson(json);
  }
}

//------------------ HEALTH CHECK REQUEST ------------------\\
///only what the admin writes: `state` is read-only
class HealthCheckRequest {
  final bool enabled;
  final String path;
  final int intervalSeconds;

  HealthCheckRequest({
    required this.enabled,
    required this.path,
    required this.intervalSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'path': path,
      'interval_seconds': intervalSeconds,
    };
  }
}

//------------------ HEALTH CHECK RESPONSE ------------------\\
class HealthCheckResponse {
  final bool enabled;
  final String path;
  final int intervalSeconds;

  //read-only `state`, written by the gateway; null until the first call
  final String? checkedAt;
  final bool? up;
  final int? status;
  final int? millis;

  HealthCheckResponse({
    required this.enabled,
    required this.path,
    required this.intervalSeconds,
    this.checkedAt,
    this.up,
    this.status,
    this.millis,
  });

  ///null when it isn't configured (`health_check: null`) or the route can't have one (no key)
  static HealthCheckResponse? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic> ||
        json['enabled'] is! bool ||
        json['path'] is! String ||
        json['interval_seconds'] is! int) {
      return null;
    }
    final state = json['state'];
    return HealthCheckResponse(
      enabled: json['enabled'] as bool,
      path: json['path'] as String,
      intervalSeconds: json['interval_seconds'] as int,
      checkedAt: state is Map ? state['checked_at'] as String? : null,
      up: state is Map ? state['up'] as bool? : null,
      status: state is Map ? state['status'] as int? : null,
      millis: state is Map ? state['millis'] as int? : null,
    );
  }
}

//------------------ RATE LIMIT REQUEST ------------------\\
class RateLimitRequest {
  final bool enabled;
  final int limit;
  final String period;
  final int? burst;

  RateLimitRequest({
    required this.enabled,
    required this.limit,
    required this.period,
    this.burst,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'limit': limit,
    'period': period,
    'burst': burst,
  };
}

//------------------ RATE LIMIT RESPONSE ------------------\\
///the api answers exactly what was saved (no read-only fields)
class RateLimitResponse {
  final bool enabled;
  final int limit;
  final String period;
  final int? burst;

  RateLimitResponse({
    required this.enabled,
    required this.limit,
    required this.period,
    this.burst,
  });

  ///null when it isn't configured (`rate_limit: null`) or can't be (no key)
  static RateLimitResponse? tryFromJson(dynamic json) {
    if (json is! Map ||
        json['enabled'] is! bool ||
        json['limit'] is! int ||
        json['period'] is! String) {
      return null;
    }
    return RateLimitResponse(
      enabled: json['enabled'] as bool,
      limit: json['limit'] as int,
      period: json['period'] as String,
      burst: json['burst'] as int?,
    );
  }
}

//------------------ CORS REQUEST ------------------\\
class CorsRequest {
  final bool enabled;
  final List<String> allowedOrigins;
  final bool allowCredentials;

  CorsRequest({
    required this.enabled,
    required this.allowedOrigins,
    required this.allowCredentials,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'allowed_origins': allowedOrigins,
    'allow_credentials': allowCredentials,
  };
}

//------------------ CORS RESPONSE ------------------\\
class CorsResponse {
  final bool enabled;
  final List<String> allowedOrigins;
  final bool allowCredentials;

  ///gateway only, read-only: `CORS_ALLOWED_ORIGINS` when it's set (deprecated, gone in 7.0)
  final CorsEnvVarResponse? envVar;

  CorsResponse({
    required this.enabled,
    required this.allowedOrigins,
    required this.allowCredentials,
    this.envVar,
  });

  ///null when it isn't configured (`cors: null`) or can't be (no key)
  static CorsResponse? tryFromJson(dynamic json) {
    if (json is! Map ||
        json['enabled'] is! bool ||
        json['allowed_origins'] is! List) {
      return null;
    }
    return CorsResponse(
      enabled: json['enabled'] as bool,
      allowedOrigins: (json['allowed_origins'] as List)
          .whereType<String>()
          .toList(),
      allowCredentials: json['allow_credentials'] == true,
      envVar: CorsEnvVarResponse.tryFromJson(json['env_var']),
    );
  }
}

//------------------ CORS ENV VAR RESPONSE ------------------\\
class CorsEnvVarResponse {
  final String name;
  final List<String> origins;
  final bool matches;

  CorsEnvVarResponse({
    required this.name,
    required this.origins,
    required this.matches,
  });

  ///null when it isn't set, or on a gateway that doesn't send it
  static CorsEnvVarResponse? tryFromJson(dynamic json) {
    if (json is! Map || json['matches'] is! bool) return null;
    return CorsEnvVarResponse(
      name: json['name'] is String
          ? json['name'] as String
          : 'CORS_ALLOWED_ORIGINS',
      origins: json['origins'] is List
          ? (json['origins'] as List).whereType<String>().toList()
          : const [],
      matches: json['matches'] as bool,
    );
  }
}

import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class RoutesClient extends BaseClient {
  @override
  String get baseUrl => '${Environment.baseApiUrl}/routes';

  RoutesClient(super.dio);

  Future<List<RouteResponse>> findAll() async {
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

  Future details({required String routeId}) async {
    Response rawResponse = await dio.get('$baseUrl/$routeId');
    return RouteResponse.fromJson(rawResponse.data! as Map<String, dynamic>);
  }

  ///add-ons of a route, or of the gateway when [routeId] is null
  String _addons(String? routeId) => routeId == null
      ? '${Environment.baseApiUrl}/addons'
      : '$baseUrl/$routeId/addons';

  ///the gateway's add-ons: its maintenance, null when it isn't configured
  Future<MaintenanceEntity?> findGatewayMaintenance() async {
    Response rawResponse = await dio.get(_addons(null));
    final data = rawResponse.data;
    return MaintenanceEntity.tryFromJson(
      data is Map ? data['maintenance'] : null,
    );
  }

  ///creates or replaces it: 200 with the saved object; 404 when the route doesn't exist, 422 when invalid
  Future<MaintenanceEntity> putMaintenance({
    required MaintenanceEntity model,
    String? routeId,
  }) async {
    Response rawResponse = await dio.put(
      '${_addons(routeId)}/maintenance',
      data: model.toJson(),
    );
    return MaintenanceEntity.fromJson(rawResponse.data as Map<String, dynamic>);
  }

  ///only routes: the gateway's can't be deleted
  Future deleteMaintenance({required String routeId}) async {
    await dio.delete('${_addons(routeId)}/maintenance');
  }

  ///idempotent; 404 when it isn't configured
  Future<MaintenanceEntity> setMaintenanceEnabled({
    required bool enabled,
    String? routeId,
  }) async {
    Response rawResponse = await dio.post(
      '${_addons(routeId)}/maintenance/${enabled ? 'enable' : 'disable'}',
    );
    return MaintenanceEntity.fromJson(rawResponse.data as Map<String, dynamic>);
  }
}

class RouteRequest {
  final String name;
  final String path;
  final String uri;
  //optional in the api: null = no rewrite filter
  final RewritePathEntity? rewritePath;
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

  factory RouteRequest.fromJson(Map<String, dynamic> json) {
    return RouteRequest(
      name: json['name'],
      path: json['path'],
      uri: json['uri'],
      rewritePath: RewritePathEntity.tryFromJson(json['rewrite_path']),
      description: json['description'] ?? '',
      addons: json['addons'] is Map<String, dynamic> ? json['addons'] : null,
    );
  }
}

class RouteResponse {
  final String id;
  final String createdAt;

  final String name;
  final String path;
  final String uri;
  final RewritePathEntity? rewritePath;
  final String description;

  ///every add-on this gateway knows, `null` the ones not configured; kept whole for the backup
  final Map<String, dynamic> addons;

  MaintenanceEntity? get maintenance =>
      MaintenanceEntity.tryFromJson(addons['maintenance']);

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
      rewritePath: RewritePathEntity.tryFromJson(json['rewrite_path']),
      description: json['description'] ?? '',
      createdAt: json['created_at'],
      addons: json['addons'] is Map<String, dynamic> ? json['addons'] : {},
    );
  }
}

class MaintenanceEntity {
  final bool enabled;
  final String? message;
  //ISO-8601 with offset
  final String? retryAfter;

  //read-only, written by the gateway
  final String? defaultMessage;
  final String? enabledAt;
  final String? disabledAt;

  MaintenanceEntity({
    required this.enabled,
    this.message,
    this.retryAfter,
    this.defaultMessage,
    this.enabledAt,
    this.disabledAt,
  });

  factory MaintenanceEntity.fromJson(Map<String, dynamic> json) {
    final state = json['state'];
    return MaintenanceEntity(
      enabled: json['enabled'] as bool,
      message: json['message'] as String?,
      retryAfter: json['retry_after'] as String?,
      defaultMessage: json['default_message'] as String?,
      enabledAt: state is Map ? state['enabled_at'] as String? : null,
      disabledAt: state is Map ? state['disabled_at'] as String? : null,
    );
  }

  ///null when it isn't configured (the api sends `maintenance: null`)
  static MaintenanceEntity? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic> || json['enabled'] is! bool) return null;
    return MaintenanceEntity.fromJson(json);
  }

  ///only what the admin writes: `default_message` and `state` are read-only
  Map<String, dynamic> toJson() {
    return {'enabled': enabled, 'message': message, 'retry_after': retryAfter};
  }
}

class RewritePathEntity {
  final String replaceFrom;
  final String replaceTo;

  RewritePathEntity({required this.replaceFrom, required this.replaceTo});

  ///null when the route has no rewrite (api sends `rewrite_path: null`)
  static RewritePathEntity? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final from = json['replace_from'];
    final to = json['replace_to'];
    if (from is! String || to is! String) return null;
    return RewritePathEntity(replaceFrom: from, replaceTo: to);
  }

  Map<String, dynamic> toJson() {
    return {'replace_from': replaceFrom, 'replace_to': replaceTo};
  }
}

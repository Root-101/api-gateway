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

  ///200 with the saved object, 404 when the route doesn't exist, 422 when [model] is invalid
  Future<MaintenanceEntity> setMaintenance({
    required String routeId,
    required MaintenanceEntity model,
  }) async {
    Response rawResponse = await dio.put(
      '$baseUrl/$routeId/maintenance',
      data: model.toJson(),
    );
    return MaintenanceEntity.fromJson(rawResponse.data as Map<String, dynamic>);
  }

  ///the gateway-wide maintenance, null when it was never set
  Future<MaintenanceEntity?> findGlobalMaintenance() async {
    Response rawResponse = await dio.get(
      '${Environment.baseApiUrl}/maintenance',
    );
    return MaintenanceEntity.tryFromJson(rawResponse.data);
  }

  Future<MaintenanceEntity> setGlobalMaintenance({
    required MaintenanceEntity model,
  }) async {
    Response rawResponse = await dio.put(
      '${Environment.baseApiUrl}/maintenance',
      data: model.toJson(),
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
  //only restore (PUT /routes) applies it; create, edit and validate ignore it
  final MaintenanceEntity? maintenance;

  RouteRequest({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    this.rewritePath,
    this.maintenance,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'uri': uri,
      'description': description,
      'rewrite_path': rewritePath?.toJson(),
      if (maintenance != null) 'maintenance': maintenance!.toJson(),
    };
  }

  factory RouteRequest.fromJson(Map<String, dynamic> json) {
    return RouteRequest(
      name: json['name'],
      path: json['path'],
      uri: json['uri'],
      rewritePath: RewritePathEntity.tryFromJson(json['rewrite_path']),
      description: json['description'] ?? '',
      maintenance: MaintenanceEntity.tryFromJson(json['maintenance']),
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
  final MaintenanceEntity? maintenance;

  RouteResponse({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    required this.id,
    required this.createdAt,
    this.rewritePath,
    this.maintenance,
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
      maintenance: MaintenanceEntity.tryFromJson(json['maintenance']),
    );
  }
}

class MaintenanceEntity {
  final bool enabled;
  final String? message;
  //ISO-8601 with offset
  final String? retryAfter;

  MaintenanceEntity({required this.enabled, this.message, this.retryAfter});

  factory MaintenanceEntity.fromJson(Map<String, dynamic> json) {
    return MaintenanceEntity(
      enabled: json['enabled'] as bool,
      message: json['message'] as String?,
      retryAfter: json['retry_after'] as String?,
    );
  }

  ///null when it was never set (api sends `maintenance: null`)
  static MaintenanceEntity? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic> || json['enabled'] is! bool) return null;
    return MaintenanceEntity.fromJson(json);
  }

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

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

  Future create({required RouteRequest model}) async {
    await dio.post(baseUrl, data: model.toJson());
  }

  Future createAll({required List<RouteRequest> models}) async {
    await dio.post(
      '$baseUrl/multi-add',
      data: models.map((e) => e.toJson()).toList(),
    );
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
}

class RouteRequest {
  final String name;
  final String path;
  final String uri;
  //optional in the api: null = no rewrite filter
  final RewritePathEntity? rewritePath;
  final String description;
  final RouteAdvancedModel advanced;

  RouteRequest({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    this.rewritePath,
    this.advanced = const RouteAdvancedModel(),
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'uri': uri,
      'description': description,
      'rewrite_path': rewritePath?.toJson(),
      ...advanced.toJson(),
    };
  }

  factory RouteRequest.fromJson(Map<String, dynamic> json) {
    return RouteRequest(
      name: json['name'],
      path: json['path'],
      uri: json['uri'],
      rewritePath: RewritePathEntity.tryFromJson(json['rewrite_path']),
      description: json['description'] ?? '',
      advanced: RouteAdvancedModel.fromJson(json),
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
  final RouteAdvancedModel advanced;

  RouteResponse({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    required this.id,
    required this.createdAt,
    this.rewritePath,
    this.advanced = const RouteAdvancedModel(),
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
      advanced: RouteAdvancedModel.fromJson(json),
    );
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

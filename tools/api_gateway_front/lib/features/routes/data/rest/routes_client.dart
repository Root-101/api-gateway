import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';

class RoutesClient extends BaseClient {
  @override
  String get baseUrl => '${Environment.baseApiUrl}/routes';

  RoutesClient(super.dio);

  Future<List<RouteResponse>> findAll({
    required CredentialsModel credential,
  }) async {
    Response rawResponse = await dio.get(
      baseUrl,
      options: options(credential: credential),
    );

    return rawResponse.data!
        .map((dynamic i) => RouteResponse.fromJson(i as Map<String, dynamic>))
        .toList()
        .cast<RouteResponse>();
  }

  Future create({
    required CredentialsModel credential,
    required RouteRequest model,
  }) async {
    await dio.post(
      baseUrl,
      options: options(credential: credential),
      data: model.toJson(),
    );
  }

  Future createAll({
    required CredentialsModel credential,
    required List<RouteRequest> models,
  }) async {
    await dio.post(
      '$baseUrl/multi-add',
      options: options(credential: credential),
      data: models.map((e) => e.toJson()).toList(),
    );
  }

  Future edit({
    required CredentialsModel credential,
    required String routeId,
    required RouteRequest model,
  }) async {
    await dio.put(
      '$baseUrl/$routeId',
      options: options(credential: credential),
      data: model.toJson(),
    );
  }

  Future delete({
    required CredentialsModel credential,
    required String routeId,
  }) async {
    await dio.delete(
      '$baseUrl/$routeId',
      options: options(credential: credential),
    );
  }

  Future details({
    required CredentialsModel credential,
    required String routeId,
  }) async {
    Response rawResponse = await dio.get(
      '$baseUrl/$routeId',
      options: options(credential: credential),
    );
    return RouteResponse.fromJson(rawResponse.data! as Map<String, dynamic>);
  }
}

class RouteRequest {
  final String name;
  final String path;
  final String uri;
  final RewritePathEntity rewritePath;
  final String description;

  RouteRequest({
    required this.name,
    required this.path,
    required this.uri,
    required this.rewritePath,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'uri': uri,
      'description': description,
      'rewrite_path': rewritePath.toJson(),
    };
  }

  factory RouteRequest.fromJson(Map<String, dynamic> json) {
    return RouteRequest(
      name: json['name'],
      path: json['path'],
      uri: json['uri'],
      rewritePath: RewritePathEntity.fromJson(json['rewrite_path']),
      description: json['description'],
    );
  }
}

class RouteResponse {
  final String id;
  final String createdAt;

  final String name;
  final String path;
  final String uri;
  final RewritePathEntity rewritePath;
  final String description;

  RouteResponse({
    required this.name,
    required this.path,
    required this.uri,
    required this.rewritePath,
    required this.description,
    required this.id,
    required this.createdAt,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      uri: json['uri'],
      rewritePath: RewritePathEntity.fromJson(json['rewrite_path']),
      description: json['description'],
      createdAt: json['created_at'],
    );
  }
}

class RewritePathEntity {
  final String replaceFrom;
  final String replaceTo;

  RewritePathEntity({required this.replaceFrom, required this.replaceTo});

  factory RewritePathEntity.fromJson(Map<String, dynamic> json) {
    return RewritePathEntity(
      replaceFrom: json['replace_from'],
      replaceTo: json['replace_to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'replace_from': replaceFrom, 'replace_to': replaceTo};
  }
}

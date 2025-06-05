import 'package:api_gateway_front/app_exporter.dart';

class RouteModel {
  final String id;
  final DateTime createdAt;

  final String name;
  final String path;
  final String uri;
  final RewritePathModel rewritePath;
  final String description;

  final String? gatewayUrl;

  String get enterPoint => '${gatewayUrl ?? ''}$path';

  ///Url of the final service where the redirect is gonna take place
  String get redirectTo =>
      '$uri$path'.replaceAll(rewritePath.replaceFrom, rewritePath.replaceTo);

  RouteModel({
    required this.name,
    required this.path,
    required this.uri,
    required this.rewritePath,
    required this.description,
    required this.id,
    required this.createdAt,
    this.gatewayUrl,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      uri: json['uri'],
      rewritePath: RewritePathModel.fromJson(json['rewrite_path']),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'uri': uri,
      'rewrite_path': rewritePath.toJson(),
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

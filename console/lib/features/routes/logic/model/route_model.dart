import 'package:console/app_exporter.dart';

class RouteModel {
  final String id;
  final DateTime createdAt;

  final String name;
  final String path;
  final String uri;
  final RewritePathModel? rewritePath;
  final String description;

  final String? gatewayUrl;

  String get enterPoint => '${gatewayUrl ?? ''}$path';

  ///Url of the final service where the redirect is gonna take place
  String get redirectTo =>
      routeRedirectUrl(uri: uri, path: path, rewrite: rewritePath);

  RouteModel({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    required this.id,
    required this.createdAt,
    this.rewritePath,
    this.gatewayUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'uri': uri,
      'rewrite_path': rewritePath?.toJson(),
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

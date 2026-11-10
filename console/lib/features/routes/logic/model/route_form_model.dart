import 'package:console/app_exporter.dart';

class RouteFormModel {
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

  RouteFormModel({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    this.rewritePath,
    this.gatewayUrl,
  });
}

import 'package:api_gateway_front/app_exporter.dart';

class RouteFormModel {
  final String name;
  final String path;
  final String uri;
  final RewritePathModel? rewritePath;
  final String description;
  final RouteAdvancedModel advanced;

  final String? gatewayUrl;

  String get enterPoint => '${gatewayUrl ?? ''}$path';

  ///Url of the final service where the redirect is gonna take place
  String get redirectTo => '$uri${rewritePath?.apply(path) ?? path}';

  RouteFormModel({
    required this.name,
    required this.path,
    required this.uri,
    required this.description,
    this.rewritePath,
    this.gatewayUrl,
    this.advanced = const RouteAdvancedModel(),
  });
}

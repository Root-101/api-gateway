import 'package:api_gateway_front/app_exporter.dart';

class RouteFormModel {
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

  RouteFormModel({
    required this.name,
    required this.path,
    required this.uri,
    required this.rewritePath,
    required this.description,
    this.gatewayUrl,
  });
}

import 'package:console/app_exporter.dart';

class RouteModel {
  final String id;
  final DateTime createdAt;

  final String name;
  final String path;
  final String uri;
  final RewritePathModel? rewritePath;
  final String description;
  final MaintenanceModel? maintenance;
  final HealthCheckModel? healthCheck;
  final RateLimitModel? rateLimit;

  ///every add-on as the api sent it (`null` the ones not configured, unknown ones too), for the backup
  final Map<String, dynamic> addons;

  final String? gatewayUrl;

  ///its own maintenance is on (the gateway's may still win, see [RouteStatus])
  bool get inMaintenance => maintenance?.enabled ?? false;

  ///the add-on types this route can have: the keys the api sends (null = not configured yet)
  bool canHave(String addon) => addons.containsKey(addon);

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
    this.maintenance,
    this.healthCheck,
    this.rateLimit,
    this.addons = const {},
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
      //every key as received (null included, unknown ones untouched), without what the gateway writes
      'addons': addons.map(
        (key, value) => MapEntry(
          key,
          value is Map<String, dynamic>
              ? (Map.of(value)
                  ..remove('default_message')
                  ..remove('state'))
              : value,
        ),
      ),
    };
  }
}

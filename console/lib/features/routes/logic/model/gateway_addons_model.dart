import 'package:console/app_exporter.dart';

///the gateway's own add-ons, each null when it isn't configured
class GatewayAddonsModel {
  final MaintenanceModel? maintenance;
  final RateLimitModel? rateLimit;
  final CorsModel? cors;

  ///false on a gateway that doesn't know the rate limit add-on (before 6.1.0)
  final bool rateLimitSupported;

  const GatewayAddonsModel({
    required this.rateLimitSupported,
    this.maintenance,
    this.rateLimit,
    this.cors,
  });
}

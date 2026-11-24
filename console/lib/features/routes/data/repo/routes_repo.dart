import 'dart:convert';

import 'package:console/app_exporter.dart';

class RoutesRepo {
  final RoutesClient client;
  final String gatewayUrl = Environment.gatewayUrl;

  RoutesRepo({required this.client});

  Future<List<RouteModel>> list() async {
    try {
      List<RouteResponse> response = await client.list();
      return response.toModel(gatewayUrl: gatewayUrl);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  ///the broken fields of [model] by their api name (empty when it's valid), checked by the api itself
  Future<Map<String, String>> validate({required RouteFormModel model}) async {
    try {
      await client.validate(model: model.toRequest());
      return {};
    } on Exception catch (exc) {
      final global = ExceptionConverter.parse(exc);
      if (global.type == GlobalExceptionType.validation &&
          global.data is List<ValidationError>) {
        return (global.data as List<ValidationError>).asFailedValidations();
      }
      throw global;
    }
  }

  Future create({required RouteFormModel model}) async {
    try {
      await client.create(model: model.toRequest());
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future edit({required String routeId, required RouteFormModel model}) async {
    try {
      await client.edit(model: model.toRequest(), routeId: routeId);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  ///parses a backup file (a non-empty list of routes with name, path and uri);
  ///wrong shapes throw TypeError (not Exception), so catch everything
  List<RouteRequest> parseBackup(String rawFileContent) {
    try {
      List<dynamic> rawList = jsonDecode(rawFileContent) as List<dynamic>;
      final routes = rawList.map((e) => RouteRequest.fromJson(e)).toList();
      if (routes.isEmpty ||
          routes.any(
            (r) => r.name.isEmpty || r.path.isEmpty || r.uri.isEmpty,
          )) {
        throw const FormatException();
      }
      return routes;
    } catch (_) {
      throw GlobalException(
        type: GlobalExceptionType.general,
        message: app.intl.restore.invalidFile,
      );
    }
  }

  Future restore({required String rawFileContent}) async {
    List<RouteRequest> models = parseBackup(rawFileContent);
    try {
      await client.replaceAll(models: models);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future delete({required RouteModel route}) async {
    try {
      await client.delete(routeId: route.id);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  ///the gateway's add-ons, each null when it isn't configured
  Future<GatewayAddonsModel> gatewayAddons() async {
    try {
      return (await client.gatewayAddons()).toModel();
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  ///creates or replaces it; a 422 arrives as a validation GlobalException (fields `enabled`, `message`)
  Future<MaintenanceModel> putMaintenance({
    required MaintenanceModel model,
    String? routeId,
  }) async {
    try {
      final response = await client.putMaintenance(
        routeId: routeId,
        model: model.toRequest(),
      );
      return response.toModel();
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future deleteMaintenance({String? routeId}) async {
    try {
      await client.deleteMaintenance(routeId: routeId);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future<MaintenanceModel> setMaintenanceEnabled({
    required bool enabled,
    String? routeId,
  }) async {
    try {
      final response = await client.setMaintenanceEnabled(
        routeId: routeId,
        enabled: enabled,
      );
      return response.toModel();
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  ///[routeId] null = the gateway's
  Future<RateLimitModel?> putRateLimit({
    required RateLimitModel model,
    String? routeId,
  }) async {
    try {
      return (await client.putRateLimit(
        model: model.toRequest(),
        routeId: routeId,
      ))?.toModel();
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future deleteRateLimit({String? routeId}) async {
    try {
      await client.deleteRateLimit(routeId: routeId);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future<RateLimitModel?> setRateLimitEnabled({
    required bool enabled,
    String? routeId,
  }) async {
    try {
      return (await client.setRateLimitEnabled(
        enabled: enabled,
        routeId: routeId,
      ))?.toModel();
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  ///[routeId] null = the gateway's
  Future<CorsModel?> putCors({
    required CorsModel model,
    String? routeId,
  }) async {
    try {
      return (await client.putCors(
        model: model.toRequest(),
        routeId: routeId,
      ))?.toModel();
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future deleteCors({required String routeId}) async {
    try {
      await client.deleteCors(routeId: routeId);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future<CorsModel?> setCorsEnabled({
    required bool enabled,
    required String routeId,
  }) async {
    try {
      return (await client.setCorsEnabled(
        enabled: enabled,
        routeId: routeId,
      ))?.toModel();
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  ///a 422 arrives as a validation GlobalException (fields `enabled`, `path`, `interval_seconds`)
  Future putHealthCheck({
    required String routeId,
    required HealthCheckModel model,
  }) async {
    try {
      await client.putHealthCheck(
        routeId: routeId,
        model: HealthCheckRequest(
          enabled: model.enabled,
          path: model.path.trim(),
          intervalSeconds: model.intervalSeconds,
        ),
      );
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future deleteHealthCheck({required String routeId}) async {
    try {
      await client.deleteHealthCheck(routeId: routeId);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future setHealthCheckEnabled({
    required String routeId,
    required bool enabled,
  }) async {
    try {
      await client.setHealthCheckEnabled(routeId: routeId, enabled: enabled);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future runHealthCheck({required String routeId}) async {
    try {
      await client.runHealthCheck(routeId: routeId);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future<RouteModel> details({required String routeId}) async {
    try {
      RouteResponse response = await client.details(routeId: routeId);
      return response.toModel(gatewayUrl: gatewayUrl);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }
}

extension RouteFormModelToRequest on RouteFormModel {
  RouteRequest toRequest() => RouteRequest(
    name: name,
    description: description,
    path: path,
    uri: uri,
    rewritePath: rewritePath == null
        ? null
        : RewritePathRequest(
            replaceFrom: rewritePath!.replaceFrom,
            replaceTo: rewritePath!.replaceTo,
          ),
  );
}

extension RouteResponseToModel on RouteResponse {
  RouteModel toModel({String? gatewayUrl}) => RouteModel(
    id: id,
    name: name,
    createdAt: DateTime.parse(createdAt),
    description: description,
    path: path,
    uri: uri,
    rewritePath: rewritePath == null
        ? null
        : RewritePathModel(
            replaceFrom: rewritePath!.replaceFrom,
            replaceTo: rewritePath!.replaceTo,
          ),
    maintenance: maintenance?.toModel(),
    healthCheck: switch (healthCheck) {
      null => null,
      final h => HealthCheckModel(
        enabled: h.enabled,
        path: h.path,
        intervalSeconds: h.intervalSeconds,
        checkedAt: DateTime.tryParse(h.checkedAt ?? ''),
        up: h.up,
        status: h.status,
        millis: h.millis,
      ),
    },
    rateLimit: rateLimit?.toModel(),
    cors: cors?.toModel(),
    addons: addons,
    gatewayUrl: gatewayUrl,
  );
}

extension MaintenanceResponseToModel on MaintenanceResponse {
  MaintenanceModel toModel() => MaintenanceModel(
    enabled: enabled,
    message: message,
    retryAfter: DateTime.tryParse(retryAfter ?? ''),
    defaultMessage: defaultMessage,
    enabledAt: DateTime.tryParse(enabledAt ?? ''),
    disabledAt: DateTime.tryParse(disabledAt ?? ''),
  );
}

extension MaintenanceModelToRequest on MaintenanceModel {
  MaintenanceRequest toRequest() => MaintenanceRequest(
    enabled: enabled,
    message: hasOwnMessage ? message!.trim() : null,
    retryAfter: retryAfter?.toUtc().toIso8601String(),
  );
}

extension RouteResponseListToModel on List<RouteResponse> {
  List<RouteModel> toModel({String? gatewayUrl}) =>
      map((singleResponse) => singleResponse.toModel(gatewayUrl: gatewayUrl))
          .toList();
}

extension GatewayAddonsResponseToModel on GatewayAddonsResponse {
  GatewayAddonsModel toModel() => GatewayAddonsModel(
    maintenance: maintenance?.toModel(),
    rateLimit: rateLimit?.toModel(),
    cors: cors?.toModel(),
    rateLimitSupported: hasRateLimitKey,
  );
}

extension RateLimitResponseToModel on RateLimitResponse {
  RateLimitModel toModel() => RateLimitModel(
    enabled: enabled,
    limit: limit,
    period: period,
    burst: burst,
  );
}

extension RateLimitModelToRequest on RateLimitModel {
  RateLimitRequest toRequest() => RateLimitRequest(
    enabled: enabled,
    limit: limit,
    period: period,
    burst: burst,
  );
}

extension CorsResponseToModel on CorsResponse {
  CorsModel toModel() => CorsModel(
    enabled: enabled,
    allowedOrigins: allowedOrigins,
    allowCredentials: allowCredentials,
    envVar: switch (envVar) {
      null => null,
      final e => CorsEnvVar(
        name: e.name,
        origins: e.origins,
        matches: e.matches,
      ),
    },
  );
}

extension CorsModelToRequest on CorsModel {
  CorsRequest toRequest() => CorsRequest(
    enabled: enabled,
    allowedOrigins: allowedOrigins,
    allowCredentials: allowCredentials,
  );
}

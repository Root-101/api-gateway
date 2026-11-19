import 'dart:convert';

import 'package:console/app_exporter.dart';

class RoutesRepo {
  final RoutesClient client;
  final String gatewayUrl = Environment.gatewayUrl;

  RoutesRepo({required this.client});

  Future<List<RouteModel>> findAll() async {
    try {
      List<RouteResponse> response = await client.findAll();
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

  ///[routeId] null = the gateway; null when it isn't configured
  Future<MaintenanceModel?> findGatewayMaintenance() async {
    try {
      return (await client.findGatewayMaintenance())?.toModel();
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
        model: model.toEntity(),
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

  Future<Map<String, dynamic>> findGatewayAddons() async {
    try {
      return await client.findGatewayAddons();
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
      return await client.putRateLimit(model: model, routeId: routeId);
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
      return await client.setRateLimitEnabled(
        enabled: enabled,
        routeId: routeId,
      );
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
      return await client.putCors(model: model, routeId: routeId);
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
      return await client.setCorsEnabled(enabled: enabled, routeId: routeId);
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
        model: HealthCheckEntity(
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

extension RouteRequestParser on RouteFormModel {
  RouteRequest toRequest() => RouteRequest(
    name: name,
    description: description,
    path: path,
    uri: uri,
    rewritePath: rewritePath == null
        ? null
        : RewritePathEntity(
            replaceFrom: rewritePath!.replaceFrom,
            replaceTo: rewritePath!.replaceTo,
          ),
  );
}

extension RouteModelParser on RouteResponse {
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
    rateLimit: RateLimitModel.tryFromJson(addons['rate_limit']),
    cors: CorsModel.tryFromJson(addons['cors']),
    addons: addons,
    gatewayUrl: gatewayUrl,
  );
}

extension MaintenanceModelParser on MaintenanceEntity {
  MaintenanceModel toModel() => MaintenanceModel(
    enabled: enabled,
    message: message,
    retryAfter: DateTime.tryParse(retryAfter ?? ''),
    defaultMessage: defaultMessage,
    enabledAt: DateTime.tryParse(enabledAt ?? ''),
    disabledAt: DateTime.tryParse(disabledAt ?? ''),
  );
}

extension MaintenanceEntityParser on MaintenanceModel {
  MaintenanceEntity toEntity() => MaintenanceEntity(
    enabled: enabled,
    message: hasOwnMessage ? message!.trim() : null,
    retryAfter: retryAfter?.toUtc().toIso8601String(),
  );
}

extension RouteModelListParser on List<RouteResponse> {
  List<RouteModel> toModel({String? gatewayUrl}) =>
      map((singleResponse) => singleResponse.toModel(gatewayUrl: gatewayUrl))
          .toList();
}

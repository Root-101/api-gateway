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
    gatewayUrl: gatewayUrl,
  );
}

extension RouteModelListParser on List<RouteResponse> {
  List<RouteModel> toModel({String? gatewayUrl}) =>
      map((singleResponse) => singleResponse.toModel(gatewayUrl: gatewayUrl))
          .toList();
}

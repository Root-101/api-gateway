import 'dart:convert';

import 'package:api_gateway_front/app_exporter.dart';

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

  ///parses a backup file; wrong shapes throw TypeError (not Exception), so catch everything
  List<RouteRequest> parseBackup(String rawFileContent) {
    try {
      List<dynamic> rawList = jsonDecode(rawFileContent) as List<dynamic>;
      return rawList.map((e) => RouteRequest.fromJson(e)).toList();
    } catch (_) {
      throw GlobalException(
        type: GlobalExceptionType.general,
        message: app.intl.restore.errorDecodingFile,
      );
    }
  }

  Future restore({required String rawFileContent}) async {
    List<RouteRequest> createModels = parseBackup(rawFileContent);
    if (createModels.isNotEmpty) {
      try {
        await client.createAll(models: createModels);
      } on Exception catch (exc) {
        throw ExceptionConverter.parse(exc);
      }
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
    advanced: advanced,
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
    advanced: advanced,
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

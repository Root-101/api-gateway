import 'dart:convert';

import 'package:api_gateway_front/app_exporter.dart';

class RoutesRepo {
  final RoutesClient client;
  final String gatewayUrl = Environment.gatewayUrl;

  RoutesRepo({required this.client});

  Future<List<RouteModel>> findAll({
    required CredentialsModel credential,
  }) async {
    try {
      List<RouteResponse> response = await client.findAll(
        credential: credential,
      );
      return response.toModel(gatewayUrl: gatewayUrl);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future create({
    required CredentialsModel credential,
    required RouteFormModel model,
  }) async {
    try {
      await client.create(credential: credential, model: model.toRequest());
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future edit({
    required CredentialsModel credential,
    required String routeId,
    required RouteFormModel model,
  }) async {
    try {
      await client.edit(
        credential: credential,
        model: model.toRequest(),
        routeId: routeId,
      );
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

  Future restore({
    required CredentialsModel credential,
    required String rawFileContent,
  }) async {
    List<RouteRequest> createModels = parseBackup(rawFileContent);
    if (createModels.isNotEmpty) {
      try {
        await client.createAll(credential: credential, models: createModels);
      } on Exception catch (exc) {
        throw ExceptionConverter.parse(exc);
      }
    }
  }

  Future delete({
    required CredentialsModel credential,
    required RouteModel route,
  }) async {
    try {
      await client.delete(credential: credential, routeId: route.id);
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }

  Future<RouteModel> details({
    required CredentialsModel credential,
    required String routeId,
  }) async {
    try {
      RouteResponse response = await client.details(
        credential: credential,
        routeId: routeId,
      );
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

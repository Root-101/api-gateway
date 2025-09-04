import 'package:api_gateway_front/app_exporter.dart';

class LogsRepo {
  final LogsClient client;

  LogsRepo({required this.client});

  Future<HttpLogSearchModel> findAll({
    required CredentialsModel credential,
    required int page,
    required int size,
    int? responseCode,
    String? method,
    String? query,
    String? routeId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      HttpLogSearchResponse response = await client.findAll(
        credential: credential,
        search: HttpLogSearchRequest(
          page: page,
          size: size,
          query: query,
          responseCode: responseCode,
          method: method,
          routeId: routeId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      );
      return response.toModel();
    } on Exception catch (exc) {
      throw ExceptionConverter.parse(exc);
    }
  }
}

extension HttpLogSearchModelParser on HttpLogSearchResponse {
  HttpLogSearchModel toModel() => HttpLogSearchModel(
    page: page,
    size: size,
    totalPages: totalPages,
    totalElements: totalElements,
    pageContent: pageContent.map((log) => log.toModel()).toList(),
  );
}

extension HttpLogModelParser on HttpLogResponse {
  HttpLogModel toModel() => HttpLogModel(
    id: id,
    sourceIp: sourceIp,
    requestedAt: requestedAt,
    userAgent: userAgent,
    httpMethod: httpMethod,
    path: path,
    responseCode: responseCode,
    requestDuration: requestDuration,
    route: route?.toModel(),
  );
}

extension RouteLogModelParser on RouteLogResponse {
  RouteLogModel toModel() => RouteLogModel(
    routeId: routeId,
    routeName: routeName,
    routePath: routePath,
  );
}

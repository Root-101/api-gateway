import 'package:api_gateway_front/app_exporter.dart';
import 'package:dio/dio.dart';

class LogsClient extends BaseClient {
  @override
  String get baseUrl => '${Environment.baseApiUrl}/http-log';

  LogsClient(super.dio);

  Future<HttpLogSearchResponse> findAll({
    required CredentialsModel credential,
    required HttpLogSearchRequest search,
  }) async {
    Response rawResponse = await dio.post(
      '$baseUrl/search',
      options: options(credential: credential),
      data: search.toJson(),
    );

    return HttpLogSearchResponse.fromJson(rawResponse.data!);
  }
}

class HttpLogSearchRequest {
  final int page;
  final int size;
  final int? responseCode;
  final String? method;
  final String? query;
  final String? routeId;
  final DateTime? fromDate;
  final DateTime? toDate;

  HttpLogSearchRequest({
    required this.page,
    required this.size,
    this.responseCode,
    this.method,
    this.query,
    this.routeId,
    this.fromDate,
    this.toDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      'response_code': responseCode,
      'method': method,
      'query': query,
      'route_id': routeId,
      'from_date': fromDate?.toUtc().toIso8601String(),
      'to_date': toDate?.toUtc().toIso8601String(),
    };
  }
}

class HttpLogSearchResponse {
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final List<HttpLogResponse> pageContent;

  HttpLogSearchResponse({
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.pageContent,
  });

  factory HttpLogSearchResponse.fromJson(Map<String, dynamic> json) {
    return HttpLogSearchResponse(
      page: json['page'] ?? 0,
      size: json['size'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      totalElements: json['total_elements'] ?? 0,
      pageContent: (json['page_content'] as List<dynamic>? ?? [])
          .map((item) => HttpLogResponse.fromJson(item))
          .toList(),
    );
  }
}

class HttpLogResponse {
  final String id;
  final String sourceIp;
  final DateTime requestedAt;
  final String userAgent;
  final String httpMethod;
  final String path;
  final int responseCode;
  final int requestDuration;
  final RouteLogResponse? route;

  HttpLogResponse({
    required this.id,
    required this.sourceIp,
    required this.requestedAt,
    required this.userAgent,
    required this.httpMethod,
    required this.path,
    required this.responseCode,
    required this.requestDuration,
    this.route,
  });

  factory HttpLogResponse.fromJson(Map<String, dynamic> json) {
    return HttpLogResponse(
      id: json['id'] ?? '',
      sourceIp: json['source_ip'] ?? '',
      requestedAt:
          DateTime.tryParse(json['requested_at'] ?? '') ?? DateTime.now(),
      userAgent: json['user_agent'] ?? '',
      httpMethod: json['http_method'] ?? '',
      path: json['path'] ?? '',
      responseCode: json['response_code'] ?? 0,
      requestDuration: json['request_duration'] ?? 0,
      route: json['route'] != null
          ? RouteLogResponse.fromJson(json['route'])
          : null,
    );
  }
}

class RouteLogResponse {
  final String routeId;
  final String routeName;
  final String routePath;

  RouteLogResponse({
    required this.routeId,
    required this.routeName,
    required this.routePath,
  });

  factory RouteLogResponse.fromJson(Map<String, dynamic> json) {
    return RouteLogResponse(
      routeId: json['route_id'],
      routeName: json['route_name'],
      routePath: json['route_path'],
    );
  }
}

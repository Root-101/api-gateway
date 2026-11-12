import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class LogsClient extends BaseClient {
  @override
  String get baseUrl => '${Environment.baseApiUrl}/http-logs';

  LogsClient(super.dio);

  Future<HttpLogSearchResponse> findAll({
    required HttpLogSearchRequest search,
  }) async {
    Response rawResponse = await dio.get(
      baseUrl,
      queryParameters: search.toQuery(),
    );

    return HttpLogSearchResponse.fromJson(rawResponse.data!);
  }
}

class HttpLogSearchRequest {
  final int page;
  final int? size;

  ///a status prefix: `4` = 4xx, `478` = that exact code
  final String? responseCode;
  final String? method;
  final String? query;
  final String? routeId;
  final DateTime? fromDate;
  final DateTime? toDate;

  HttpLogSearchRequest({
    required this.page,
    this.size,
    this.responseCode,
    this.method,
    this.query,
    this.routeId,
    this.fromDate,
    this.toDate,
  });

  ///empty filters are left out: every parameter is optional
  Map<String, dynamic> toQuery() {
    return {
      'page': page,
      'size': ?size,
      'status': ?responseCode,
      'method': ?method,
      'query': ?query,
      'route_id': ?routeId,
      'from': ?fromDate?.toUtc().toIso8601String(),
      'to': ?toDate?.toUtc().toIso8601String(),
    };
  }
}

class HttpLogSearchResponse {
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  ///the gateway stops counting at 100 000: true when more logs match
  final bool totalCapped;
  final List<HttpLogResponse> pageContent;

  HttpLogSearchResponse({
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.pageContent,
    this.totalCapped = false,
  });

  factory HttpLogSearchResponse.fromJson(Map<String, dynamic> json) {
    return HttpLogSearchResponse(
      page: json['page'] ?? 0,
      size: json['size'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      totalElements: json['total_elements'] ?? 0,
      totalCapped: json['total_capped'] == true,
      pageContent: (json['items'] as List<dynamic>? ?? [])
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
      responseCode: (json['response_code'] as num?)?.toInt() ?? 0,
      requestDuration: (json['request_duration'] as num?)?.toInt() ?? 0,
      route: json['route'] is Map<String, dynamic>
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
      //defensive like HttpLogResponse: one bad row must not break the whole page
      routeId: json['route_id']?.toString() ?? '',
      routeName: json['route_name']?.toString() ?? '',
      routePath: json['route_path']?.toString() ?? '',
    );
  }
}

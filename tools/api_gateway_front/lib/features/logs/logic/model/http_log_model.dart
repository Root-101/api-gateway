class HttpLogSearchModel {
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final List<HttpLogModel> pageContent;

  HttpLogSearchModel({
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.pageContent,
  });

  @override
  String toString() {
    return 'HttpLogSearchModel{page: $page, size: $size, totalPages: $totalPages, totalElements: $totalElements, pageContent: $pageContent}';
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'pageContent': pageContent.map((log) => log.toJson()).toList(),
    };
  }
}

class HttpLogModel {
  final String id;
  final String sourceIp;
  final DateTime requestedAt;
  final String userAgent;
  final String httpMethod;
  final String path;
  final int responseCode;
  final int requestDuration;
  final RouteLogModel? route;

  HttpLogModel({
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

  @override
  String toString() {
    return 'HttpLogModel{id: $id}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceIp': sourceIp,
      'requestedAt': requestedAt.toUtc().toIso8601String(),
      'userAgent': userAgent,
      'httpMethod': httpMethod,
      'path': path,
      'responseCode': responseCode,
      'requestDuration': requestDuration,
      'route': route?.toJson(),
    };
  }
}

class RouteLogModel {
  final String routeId;
  final String routeName;
  final String routePath;

  RouteLogModel({
    required this.routeId,
    required this.routeName,
    required this.routePath,
  });

  @override
  String toString() {
    return 'RouteLogModel{routeId: $routeId, routeName: $routeName, routePath: $routePath}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteLogModel &&
          runtimeType == other.runtimeType &&
          routeId == other.routeId;

  @override
  int get hashCode => routeId.hashCode;

  RouteLogModel copyWith({
    String? routeId,
    String? routeName,
    String? routePath,
  }) {
    return RouteLogModel(
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      routePath: routePath ?? this.routePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': routeId, 'name': routeName, 'path': routePath};
  }
}

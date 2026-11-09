class RouteHeaderCondition {
  final String name;

  ///null: it is enough that the header exists
  final String? regexp;

  const RouteHeaderCondition({required this.name, this.regexp});

  factory RouteHeaderCondition.fromJson(Map<String, dynamic> json) =>
      RouteHeaderCondition(
        name: json['name'] as String,
        regexp: json['regexp'] as String?,
      );

  Map<String, dynamic> toJson() => {'name': name, 'regexp': regexp};
}

class RouteFilterModel {
  ///filters supported by the gateway and the exact number of args of each one
  static const Map<String, int> argCounts = {
    'AddRequestHeader': 2,
    'AddResponseHeader': 2,
    'SetRequestHeader': 2,
    'SetResponseHeader': 2,
    'RemoveRequestHeader': 1,
    'RemoveResponseHeader': 1,
  };

  final String name;
  final List<String> args;

  const RouteFilterModel({required this.name, required this.args});

  factory RouteFilterModel.fromJson(Map<String, dynamic> json) =>
      RouteFilterModel(
        name: json['name'] as String,
        args: List<String>.from(json['args'] as List),
      );

  Map<String, dynamic> toJson() => {'name': name, 'args': args};
}

///optional part of a route. The api replaces everything on PUT, so these always have to be sent back
class RouteAdvancedModel {
  static const List<String> httpMethods = [
    'GET',
    'HEAD',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS',
    'TRACE',
  ];

  final int order;
  final List<String> methods;
  final List<String> hosts;
  final List<RouteHeaderCondition> headers;
  final List<RouteFilterModel> filters;

  const RouteAdvancedModel({
    this.order = 0,
    this.methods = const [],
    this.hosts = const [],
    this.headers = const [],
    this.filters = const [],
  });

  bool get isDefault =>
      order == 0 &&
      methods.isEmpty &&
      hosts.isEmpty &&
      headers.isEmpty &&
      filters.isEmpty;

  ///the keys are missing in backups from older versions. Wrong types throw right here, not on first use
  factory RouteAdvancedModel.fromJson(Map<String, dynamic> json) =>
      RouteAdvancedModel(
        order: json['order'] as int? ?? 0,
        methods: List<String>.from(json['methods'] as List? ?? const []),
        hosts: List<String>.from(json['hosts'] as List? ?? const []),
        headers: [
          for (final header in json['headers'] as List? ?? const [])
            RouteHeaderCondition.fromJson(header as Map<String, dynamic>),
        ],
        filters: [
          for (final filter in json['filters'] as List? ?? const [])
            RouteFilterModel.fromJson(filter as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
    'order': order,
    'methods': methods,
    'hosts': hosts,
    'headers': headers.map((e) => e.toJson()).toList(),
    'filters': filters.map((e) => e.toJson()).toList(),
  };

  ///empty means the default order. `order` is a 32-bit integer in the gateway
  static bool isValidOrder(String value) {
    if (value.isEmpty) return true;
    final order = int.tryParse(value);
    return order != null && order >= -2147483648 && order <= 2147483647;
  }
}

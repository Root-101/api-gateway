import 'package:api_gateway_front/main.dart';
import 'package:go_router/go_router.dart';

class NavigatorHelper {
  static final NavigatorHelper _instance = NavigatorHelper._internal();

  NavigatorHelper._internal();

  factory NavigatorHelper() => _instance;

  //asumed `goNamed`
  void go(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    bool addToStack = true,
  }) {
    app.context.goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void push(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    bool addToStack = true,
  }) {
    app.context.pushNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void pop() {
    app.context.pop();
  }
}

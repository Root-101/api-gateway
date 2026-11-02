import 'package:flutter/material.dart';
import 'package:get/get.dart';

///The only dependency on Get (the framework behind it) must be in this class ONLY

///DI stands for Dependency Injection
///The facade reduces the coupling between the app
///and the dependency injection plugin in use.
///Get is used here, but switching to another one,
///like get_it, only means changing the find and put implementations.
///
///E.g. to switch to get_it, replace the implementation
///of `put` with: `getIt.registerSingleton<SomeDependency>(SomeDependency());`
///and of `find` with: `getIt<AppModel>();`
///or their equivalents in each case
class DI {
  static final DI _instance = DI._internal();

  DI._internal();

  factory DI() => _instance;

  S put<S>(S dependency, {String? tag}) => Get.put<S>(dependency, tag: tag);

  S find<S>({String? tag}) => Get.find<S>(tag: tag);
}

/// CubitView is a great way of quickly access your Cubit
/// without having to call app.di.find<AwesomeCubit>() yourself.
///
/// Sample:
/// ```
/// class AwesomeCubit extends Cubit<SomeState> {
///   final String title = 'My Awesome View';
/// }
///
/// class AwesomeView extends CubitView<AwesomeCubit> {
///   AwesomeView({Key key}):super(key:key);
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(
///       padding: EdgeInsets.all(20),
///       child: Text( cubit.title ),
///     );
///   }
/// }
///``
abstract class CubitView<T> extends StatelessWidget {
  const CubitView({super.key});

  T get cubit => DI().find<T>();

  @override
  Widget build(BuildContext context);
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

///La unica dependencia de Get, que es el framework por detras SOLO debe estar en esta clase

///DI stands for Dependency Injection
///La idea del facada es reducir el acoplamiento de la app
///con el plugin de inyeccion de dependncia que se use
///En este caso se esta utilizando Get, pero de cambiarse a otro,
///como get_it, es solo cambiar la implementacio del find y el put.
///
///Si se quisiera cambiar a get_it por ejemplo sustitur la implementaciones
///del `put` por: `getIt.registerSingleton<SomeDependency>(SomeDependency());`
///y del `find` por: `getIt<AppModel>();`
///o sus correspondientes en cada caso
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

  T get cubit => Get.find<T>()!;

  @override
  Widget build(BuildContext context);
}

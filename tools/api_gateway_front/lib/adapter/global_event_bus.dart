import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

///Generalizacion de la logica de publisher/subcriber para oir cambios globales
mixin GlobalEventBusCommunication<T> on Cubit<T> {
  List<StreamSubscription> subscriptions = [];

  StreamSubscription<Y> onBus<Y>(void Function(Y event) listener) {
    StreamSubscription<Y> subscription = GlobalEventBus().on<Y>().listen(
      listener,
    );

    subscriptions.add(subscription);
    return subscription;
  }

  @override
  Future<void> close() async {
    for (var element in subscriptions) {
      element.cancel();
    }

    return super.close();
  }

  @override
  void emit(T state, {bool fireBus = true}) {
    super.emit(state);
    if (fireBus) {
      GlobalEventBus().fire(state);
    }
  }
}

class GlobalEventBus {
  static final GlobalEventBus _instance = GlobalEventBus._internal();

  factory GlobalEventBus() => _instance;

  GlobalEventBus._internal();

  final StreamController<dynamic> _controller = StreamController.broadcast();

  void fire(event) => _controller.add(event);

  Stream<T> on<T>() =>
      _controller.stream.where((event) => event is T).cast<T>();
}

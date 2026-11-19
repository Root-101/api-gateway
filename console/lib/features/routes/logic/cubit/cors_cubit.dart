import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CorsAction { added, saved, enabled, disabled, deleted }

///the CORS add-on: the gateway's (kept here; only replaced, never off or removed) and saving it,
///or a route's (read from the route list, reloaded on every change)
class CorsCubit extends Cubit<CorsState>
    with GlobalEventBusCommunication<CorsState> {
  final RoutesRepo repo;

  ///null until loaded, or on a gateway older than the add-on
  CorsModel? gateway;

  ///the "migrated" banner was closed (this session only; the "ignored" one can't be)
  bool envInfoClosed = false;

  CorsCubit({required this.repo}) : super(const CorsInitialState());

  void reset() {
    gateway = null;
    envInfoClosed = false;
    emit(const CorsInitialState());
  }

  Future load() async {
    try {
      gateway = CorsModel.tryFromJson((await repo.findGatewayAddons())['cors']);
      emit(CorsLoadedState());
    } on Exception catch (exc) {
      //the panel just doesn't show it: the next load or save fixes it
      emit(CorsLoadErrorState(ExceptionConverter.parse(exc)));
    }
  }

  void closeEnvInfo() {
    envInfoClosed = true;
    emit(CorsLoadedState());
  }

  ///creates ([CorsAction.added]) or replaces it; [route] null = the gateway's
  Future<GlobalException?> put({
    required CorsModel model,
    RouteModel? route,
    CorsAction action = CorsAction.saved,
  }) =>
      _run(route, action, () => repo.putCors(routeId: route?.id, model: model));

  ///routes only: the gateway's can't be turned off
  Future<GlobalException?> setEnabled({
    required bool enabled,
    required RouteModel route,
  }) => _run(
    route,
    enabled ? CorsAction.enabled : CorsAction.disabled,
    () => repo.setCorsEnabled(routeId: route.id, enabled: enabled),
  );

  ///routes only: the gateway's can't be removed
  Future<GlobalException?> delete({required RouteModel route}) =>
      _run(route, CorsAction.deleted, () async {
        await repo.deleteCors(routeId: route.id);
        return null;
      });

  ///null when it worked; the error is also emitted, for the toast
  Future<GlobalException?> _run(
    RouteModel? route,
    CorsAction action,
    Future<CorsModel?> Function() call,
  ) async {
    try {
      emit(CorsSavingState());
      final saved = await call();
      if (route == null) gateway = saved;
      emit(CorsSaveOkState(route: route, action: action));
      return null;
    } on Exception catch (exc) {
      final error = ExceptionConverter.parse(exc);
      emit(CorsSaveErrorState(error, route: route, action: action));
      //someone else may have changed it meanwhile: show what's there now
      if (route == null && error.type != GlobalExceptionType.validation) {
        load();
      }
      return error;
    }
  }
}

abstract class CorsState {
  const CorsState();
}

class CorsInitialState extends CorsState {
  const CorsInitialState();
}

class CorsLoadedState extends CorsState {
  CorsLoadedState();
}

class CorsLoadErrorState extends CorsState {
  final GlobalException exception;

  CorsLoadErrorState(this.exception);
}

class CorsSavingState extends CorsState {
  CorsSavingState();
}

class CorsSaveOkState extends CorsState {
  ///null when it was the gateway's
  final RouteModel? route;
  final CorsAction action;

  CorsSaveOkState({required this.route, required this.action});
}

class CorsSaveErrorState extends CorsState {
  final GlobalException exception;
  final RouteModel? route;

  ///a failed save is shown in the block itself (the 400s say why); the rest as a toast
  final CorsAction action;

  CorsSaveErrorState(this.exception, {required this.action, this.route});

  bool get shownInBlock =>
      action == CorsAction.saved ||
      exception.type == GlobalExceptionType.validation;

  String get message => exception.message;
}

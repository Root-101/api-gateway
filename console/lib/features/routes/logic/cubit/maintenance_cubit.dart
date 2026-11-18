import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MaintenanceAction { added, saved, enabled, disabled, deleted }

///the maintenance add-on: the gateway's (rail, map, banner) and saving it, or a route's
class MaintenanceCubit extends Cubit<MaintenanceState>
    with GlobalEventBusCommunication<MaintenanceState> {
  final RoutesRepo repo;

  ///null when it isn't configured
  MaintenanceModel? gateway;

  bool get gatewayOn => gateway?.enabled ?? false;

  MaintenanceCubit({required this.repo})
    : super(const MaintenanceInitialState());

  void reset() {
    gateway = null;
    emit(const MaintenanceInitialState());
  }

  Future load() async {
    try {
      gateway = await repo.findGatewayMaintenance();
      emit(MaintenanceLoadedState());
    } on Exception catch (exc) {
      //no banner is better than a broken screen: the next load or save fixes it
      emit(MaintenanceLoadErrorState(ExceptionConverter.parse(exc)));
    }
  }

  ///creates ([MaintenanceAction.added]) or replaces it; [route] null = the gateway's
  Future<GlobalException?> put({
    required MaintenanceModel model,
    RouteModel? route,
    MaintenanceAction action = MaintenanceAction.saved,
  }) => _run(
    route,
    action,
    () => repo.putMaintenance(routeId: route?.id, model: model),
  );

  Future<GlobalException?> setEnabled({
    required bool enabled,
    RouteModel? route,
  }) => _run(
    route,
    enabled ? MaintenanceAction.enabled : MaintenanceAction.disabled,
    () => repo.setMaintenanceEnabled(routeId: route?.id, enabled: enabled),
  );

  ///[route] null = the gateway's
  Future<GlobalException?> delete({RouteModel? route}) =>
      _run(route, MaintenanceAction.deleted, () async {
        await repo.deleteMaintenance(routeId: route?.id);
        return null;
      });

  ///null when it worked; the error is also emitted, for the toast
  Future<GlobalException?> _run(
    RouteModel? route,
    MaintenanceAction action,
    Future<MaintenanceModel?> Function() call,
  ) async {
    try {
      emit(MaintenanceSavingState());
      final saved = await call();
      if (route == null) gateway = saved;
      emit(MaintenanceSaveOkState(route: route, action: action, model: saved));
      return null;
    } on Exception catch (exc) {
      final error = ExceptionConverter.parse(exc);
      emit(MaintenanceSaveErrorState(error, route: route));
      //someone else may have changed it meanwhile (a 404): show what's there now
      if (error.type != GlobalExceptionType.validation) {
        if (route == null) load();
      }
      return error;
    }
  }
}

abstract class MaintenanceState {
  const MaintenanceState();
}

class MaintenanceInitialState extends MaintenanceState {
  const MaintenanceInitialState();
}

class MaintenanceLoadedState extends MaintenanceState {
  MaintenanceLoadedState();
}

class MaintenanceLoadErrorState extends MaintenanceState {
  final GlobalException exception;

  MaintenanceLoadErrorState(this.exception);
}

class MaintenanceSavingState extends MaintenanceState {
  MaintenanceSavingState();
}

class MaintenanceSaveOkState extends MaintenanceState {
  ///null when it was the gateway's
  final RouteModel? route;
  final MaintenanceAction action;

  ///null after a delete
  final MaintenanceModel? model;

  MaintenanceSaveOkState({
    required this.route,
    required this.action,
    required this.model,
  });
}

class MaintenanceSaveErrorState extends MaintenanceState {
  final GlobalException exception;
  final RouteModel? route;

  MaintenanceSaveErrorState(this.exception, {this.route});

  ///a 422 names what's wrong in its violations, the rest in the message
  String get message {
    final data = exception.data;
    if (data is List<ValidationError> && data.isNotEmpty) {
      return data.map((e) => e.message).join('\n');
    }
    return exception.message;
  }
}

import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum HealthCheckAction { added, saved, enabled, disabled, deleted, checked }

///the health check add-on of a route: saving, removing and "Run now". The route list
///(reloaded on every change) is where the panel reads it from
class HealthCheckCubit extends Cubit<HealthCheckState>
    with GlobalEventBusCommunication<HealthCheckState> {
  final RoutesRepo repo;

  HealthCheckCubit({required this.repo})
    : super(const HealthCheckInitialState());

  ///creates ([HealthCheckAction.added]) or replaces it
  Future<GlobalException?> put({
    required RouteModel route,
    required HealthCheckModel model,
    HealthCheckAction action = HealthCheckAction.saved,
  }) => _run(
    route,
    action,
    () => repo.putHealthCheck(routeId: route.id, model: model),
  );

  Future<GlobalException?> delete({required RouteModel route}) =>
      _run(route, HealthCheckAction.deleted, () async {
        await repo.deleteHealthCheck(routeId: route.id);
      });

  ///on: called every interval; off: only by Run now. Keeps the rest
  Future<GlobalException?> setEnabled({
    required RouteModel route,
    required bool enabled,
  }) => _run(
    route,
    enabled ? HealthCheckAction.enabled : HealthCheckAction.disabled,
    () => repo.setHealthCheckEnabled(routeId: route.id, enabled: enabled),
  );

  ///calls it now (up to ~5 s), on or off
  Future<GlobalException?> runNow({required RouteModel route}) => _run(
    route,
    HealthCheckAction.checked,
    () => repo.runHealthCheck(routeId: route.id),
  );

  ///null when it worked; the error is also emitted, for the toast
  Future<GlobalException?> _run(
    RouteModel route,
    HealthCheckAction action,
    Future<void> Function() call,
  ) async {
    try {
      emit(HealthCheckSavingState());
      await call();
      emit(HealthCheckSaveOkState(route: route, action: action));
      return null;
    } on Exception catch (exc) {
      final error = ExceptionConverter.parse(exc);
      emit(HealthCheckSaveErrorState(error, route: route));
      return error;
    }
  }
}

abstract class HealthCheckState {
  const HealthCheckState();
}

class HealthCheckInitialState extends HealthCheckState {
  const HealthCheckInitialState();
}

class HealthCheckSavingState extends HealthCheckState {
  HealthCheckSavingState();
}

class HealthCheckSaveOkState extends HealthCheckState {
  final RouteModel route;
  final HealthCheckAction action;

  HealthCheckSaveOkState({required this.route, required this.action});
}

class HealthCheckSaveErrorState extends HealthCheckState {
  final GlobalException exception;
  final RouteModel route;

  HealthCheckSaveErrorState(this.exception, {required this.route});

  ///a 422 names what's wrong in its errors, the rest in the message
  String get message {
    final data = exception.data;
    if (data is List<ValidationError> && data.isNotEmpty) {
      return data.map((e) => e.message).join('\n');
    }
    return exception.message;
  }
}

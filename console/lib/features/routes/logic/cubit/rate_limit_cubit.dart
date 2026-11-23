import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum RateLimitAction { added, saved, enabled, disabled, deleted }

///the rate limit add-on: the gateway's (kept here) and saving it, or a route's (read from the
///route list, reloaded on every change)
class RateLimitCubit extends Cubit<RateLimitState>
    with GlobalEventBusCommunication<RateLimitState> {
  final RoutesRepo repo;

  ///null when it isn't configured
  RateLimitModel? gateway;

  ///the gateway lists `rate_limit` in its add-ons (an older one doesn't)
  bool gatewayCanHave = false;

  RateLimitCubit({required this.repo}) : super(const RateLimitInitialState());

  void reset() {
    gateway = null;
    gatewayCanHave = false;
    emit(const RateLimitInitialState());
  }

  Future load() async {
    try {
      final addons = await repo.findGatewayAddons();
      gatewayCanHave = addons.containsKey('rate_limit');
      gateway = RateLimitModel.tryFromJson(addons['rate_limit']);
      emit(RateLimitLoadedState());
    } on Exception catch (exc) {
      //the panel just doesn't show it: the next load or save fixes it
      emit(RateLimitLoadErrorState(ExceptionConverter.parse(exc)));
    }
  }

  ///creates ([RateLimitAction.added]) or replaces it; [route] null = the gateway's
  Future<GlobalException?> put({
    required RateLimitModel model,
    RouteModel? route,
    RateLimitAction action = RateLimitAction.saved,
  }) => _run(
    route,
    action,
    () => repo.putRateLimit(routeId: route?.id, model: model),
  );

  Future<GlobalException?> setEnabled({
    required bool enabled,
    RouteModel? route,
  }) => _run(
    route,
    enabled ? RateLimitAction.enabled : RateLimitAction.disabled,
    () => repo.setRateLimitEnabled(routeId: route?.id, enabled: enabled),
  );

  ///[route] null = the gateway's
  Future<GlobalException?> delete({RouteModel? route}) =>
      _run(route, RateLimitAction.deleted, () async {
        await repo.deleteRateLimit(routeId: route?.id);
        return null;
      });

  ///null when it worked; the error is also emitted, for the toast
  Future<GlobalException?> _run(
    RouteModel? route,
    RateLimitAction action,
    Future<RateLimitModel?> Function() call,
  ) async {
    try {
      emit(RateLimitSavingState());
      final saved = await call();
      if (route == null) gateway = saved;
      emit(RateLimitSaveOkState(route: route, action: action));
      return null;
    } on Exception catch (exc) {
      final error = ExceptionConverter.parse(exc);
      emit(RateLimitSaveErrorState(error, route: route));
      //someone else may have changed it meanwhile (a 404): show what's there now
      if (route == null && error.type != GlobalExceptionType.validation) {
        load();
      }
      return error;
    }
  }
}

abstract class RateLimitState {
  const RateLimitState();
}

class RateLimitInitialState extends RateLimitState {
  const RateLimitInitialState();
}

class RateLimitLoadedState extends RateLimitState {
  RateLimitLoadedState();
}

class RateLimitLoadErrorState extends RateLimitState {
  final GlobalException exception;

  RateLimitLoadErrorState(this.exception);
}

class RateLimitSavingState extends RateLimitState {
  RateLimitSavingState();
}

class RateLimitSaveOkState extends RateLimitState {
  ///null when it was the gateway's
  final RouteModel? route;
  final RateLimitAction action;

  RateLimitSaveOkState({required this.route, required this.action});
}

class RateLimitSaveErrorState extends RateLimitState {
  final GlobalException exception;
  final RouteModel? route;

  RateLimitSaveErrorState(this.exception, {this.route});

  ///a 422 names what's wrong in its errors, the rest in the message
  String get message {
    final data = exception.data;
    if (data is List<ValidationError> && data.isNotEmpty) {
      return data.map((e) => e.message).join('\n');
    }
    return exception.message;
  }
}

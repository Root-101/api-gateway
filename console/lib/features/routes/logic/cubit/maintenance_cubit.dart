import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///maintenance of the whole gateway (shown in the rail and the banner) and saving it, or a route's
class MaintenanceCubit extends Cubit<MaintenanceState>
    with GlobalEventBusCommunication<MaintenanceState> {
  final RoutesRepo repo;

  ///null when it was never set
  MaintenanceModel? global;

  bool get globalOn => global?.enabled ?? false;

  MaintenanceCubit({required this.repo})
    : super(const MaintenanceInitialState());

  void reset() {
    global = null;
    emit(const MaintenanceInitialState());
  }

  Future load() async {
    try {
      global = await repo.findGlobalMaintenance();
      emit(MaintenanceLoadedState());
    } on Exception catch (exc) {
      //no banner is better than a broken screen: the next load or save fixes it
      emit(MaintenanceLoadErrorState(ExceptionConverter.parse(exc)));
    }
  }

  ///[route] null saves the global one
  Future save({required MaintenanceModel model, RouteModel? route}) async {
    try {
      emit(MaintenanceSavingState());
      if (route == null) {
        global = await repo.setGlobalMaintenance(model: model);
      } else {
        await repo.setMaintenance(routeId: route.id, model: model);
      }
      emit(MaintenanceSaveOkState(route: route, model: model));
    } on Exception catch (exc) {
      emit(MaintenanceSaveErrorState(ExceptionConverter.parse(exc)));
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
  ///null when the global one was saved
  final RouteModel? route;
  final MaintenanceModel model;

  MaintenanceSaveOkState({required this.route, required this.model});
}

class MaintenanceSaveErrorState extends MaintenanceState {
  final GlobalException exception;

  MaintenanceSaveErrorState(this.exception);

  ///a 422 names what's wrong in its violations, the rest in the message
  String get message {
    final data = exception.data;
    if (data is List<ValidationError> && data.isNotEmpty) {
      return data.map((e) => e.message).join('\n');
    }
    return exception.message;
  }
}

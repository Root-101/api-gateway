import 'dart:convert';

import 'package:console/app_exporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesCubit extends Cubit<RoutesState>
    with GlobalEventBusCommunication<RoutesState> {
  final RoutesRepo repo;

  ///last list loaded: survives the action states and a failed reload
  final List<RouteModel> routes = [];
  bool loaded = false;

  ///text of the search box, also set from outside ("Open route x" in the log details)
  final ValueNotifier<String> query = ValueNotifier('');

  RoutesCubit({required this.repo}) : super(const RoutesInitialState()) {
    //if a new route is added/edited, update
    onBus<RoutesFormProcessingOKState>((event) {
      search(emitLoading: false);
    });

    //if a route is deleted, update
    onBus<RoutesDeletedOkState>((event) {
      search(emitLoading: false);
    });

    //if routes are restored, update
    onBus<RoutesRestoredOkState>((event) {
      search(emitLoading: false);
    });

    //if a route's maintenance changes (or failed: someone may have changed it meanwhile), update
    onBus<MaintenanceSavedOkState>((event) {
      if (event.route != null) search(emitLoading: false);
    });
    //same for its rate limit
    onBus<RateLimitSavedOkState>((event) {
      if (event.route != null) search(emitLoading: false);
    });
    onBus<RateLimitSavingErrorState>((event) {
      if (event.route != null &&
          event.exception.type != GlobalExceptionType.validation) {
        search(emitLoading: false);
      }
    });
    //same for its CORS
    onBus<CorsSavedOkState>((event) {
      if (event.route != null) search(emitLoading: false);
    });
    onBus<CorsSavingErrorState>((event) {
      if (event.route != null &&
          event.exception.type != GlobalExceptionType.validation) {
        search(emitLoading: false);
      }
    });
    //same for its health check ("Run now" too: the new state is in the route)
    onBus<HealthCheckSavedOkState>((event) => search(emitLoading: false));
    onBus<HealthCheckSavingErrorState>((event) {
      if (event.exception.type != GlobalExceptionType.validation) {
        search(emitLoading: false);
      }
    });
    onBus<MaintenanceSavingErrorState>((event) {
      if (event.route != null &&
          event.exception.type != GlobalExceptionType.validation) {
        search(emitLoading: false);
      }
    });
  }

  void reset() {
    _seq++; //a search still on its way after logout is dropped
    routes.clear();
    loaded = false;
    query.value = '';
    emit(const RoutesInitialState());
  }

  ///number of the latest search: an older one that answers later is dropped
  int _seq = 0;

  Future search({bool emitLoading = true}) async {
    final my = ++_seq;
    try {
      //if there is a delete, create, restore, don't show the loading, just add/remove the route
      if (emitLoading) {
        emit(RoutesSearchingState());
      }

      final found = await repo.list();
      if (my != _seq) return;
      routes
        ..clear()
        ..addAll(found);
      loaded = true;

      emit(RoutesSearchOkState(routes: routes));
    } on Exception catch (exc) {
      if (my != _seq) return;
      emit(RoutesSearchErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future delete({required RouteModel route}) async {
    try {
      emit(RoutesDeletingState());

      await repo.delete(route: route);

      emit(RoutesDeletedOkState(route.name));
    } on Exception catch (exc) {
      emit(RoutesDeletingErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future backup() async {
    try {
      emit(RoutesBackingUpState());

      List<RouteModel> routes = await repo.list();
      final stamp = app.dateFormatter.fileStamp.format(DateTime.now());
      final encoder = const JsonEncoder.withIndent('  ');
      String rawData = encoder.convert(routes.map((e) => e.toJson()).toList());
      ExportDocument.downloadDocument(
        rawData,
        filename: 'routes-backup-$stamp.json',
      );

      emit(RoutesBackedUpOkState(routes.length));
    } on Exception catch (exc) {
      emit(RoutesBackingUpErrorState(ExceptionConverter.parse(exc)));
    }
  }
}

abstract class RoutesState {
  const RoutesState();
}

final class RoutesInitialState extends RoutesState {
  const RoutesInitialState();
}

//------------------------- SEARCH -------------------------\\
abstract class RoutesSearchState extends RoutesState {
  RoutesSearchState();
}

final class RoutesSearchingState extends RoutesSearchState {
  RoutesSearchingState();
}

final class RoutesSearchOkState extends RoutesSearchState {
  final List<RouteModel> routes;

  RoutesSearchOkState({required this.routes});
}

final class RoutesSearchErrorState extends RoutesSearchState {
  GlobalException exception;

  RoutesSearchErrorState(this.exception);
}

//------------------------- BACKUP -------------------------\\
abstract class RoutesBackupState extends RoutesState {
  RoutesBackupState();
}

final class RoutesBackingUpState extends RoutesBackupState {
  RoutesBackingUpState();
}

final class RoutesBackedUpOkState extends RoutesBackupState {
  final int count;

  RoutesBackedUpOkState(this.count);
}

final class RoutesBackingUpErrorState extends RoutesBackupState {
  GlobalException exception;

  RoutesBackingUpErrorState(this.exception);
}

//------------------------- DELETE -------------------------\\
abstract class RoutesDeleteState extends RoutesState {
  RoutesDeleteState();
}

final class RoutesDeletingState extends RoutesDeleteState {
  RoutesDeletingState();
}

final class RoutesDeletedOkState extends RoutesDeleteState {
  final String name;

  RoutesDeletedOkState(this.name);
}

final class RoutesDeletingErrorState extends RoutesDeleteState {
  GlobalException exception;

  RoutesDeletingErrorState(this.exception);
}

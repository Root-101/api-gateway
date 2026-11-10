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
    onBus<RoutesDeleteOkState>((event) {
      search(emitLoading: false);
    });

    //if routes are restored, update
    onBus<RoutesRestoreOkState>((event) {
      search(emitLoading: false);
    });
  }

  void reset() {
    routes.clear();
    loaded = false;
    query.value = '';
    emit(const RoutesInitialState());
  }

  Future search({bool emitLoading = true}) async {
    try {
      //if there is a delete, create, restore, don't show the loading, just add/remove the route
      if (emitLoading) {
        emit(RoutesSearchingState());
      }

      final found = await repo.findAll();
      routes
        ..clear()
        ..addAll(found);
      loaded = true;

      emit(RoutesSearchOkState(routes: routes));
    } on Exception catch (exc) {
      emit(RoutesSearchErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future delete({required RouteModel route}) async {
    try {
      emit(RoutesDeleteProcessingState());

      await repo.delete(route: route);

      emit(RoutesDeleteOkState(route.name));
    } on Exception catch (exc) {
      emit(RoutesDeleteErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future backup() async {
    try {
      emit(RoutesBackupProcessingState());

      List<RouteModel> routes = await repo.findAll();
      final stamp = app.dateFormatter.fileStamp.format(DateTime.now());
      final encoder = const JsonEncoder.withIndent('  ');
      String rawData = encoder.convert(routes.map((e) => e.toJson()).toList());
      ExportDocument.downloadDocument(
        rawData,
        filename: 'routes-backup-$stamp.json',
      );

      emit(RoutesBackupOkState(routes.length));
    } on Exception catch (exc) {
      emit(RoutesBackupErrorState(ExceptionConverter.parse(exc)));
    }
  }
}

abstract class RoutesState {
  const RoutesState();
}

class RoutesInitialState extends RoutesState {
  const RoutesInitialState();
}

//------------------------- SEARCH -------------------------\\
abstract class RoutesSearchState extends RoutesState {
  RoutesSearchState();
}

class RoutesSearchingState extends RoutesSearchState {
  RoutesSearchingState();
}

class RoutesSearchOkState extends RoutesSearchState {
  final List<RouteModel> routes;

  RoutesSearchOkState({required this.routes});
}

class RoutesSearchErrorState extends RoutesSearchState {
  GlobalException exception;

  RoutesSearchErrorState(this.exception);
}

//------------------------- BACKUP -------------------------\\
abstract class RoutesBackupState extends RoutesState {
  RoutesBackupState();
}

class RoutesBackupProcessingState extends RoutesBackupState {
  RoutesBackupProcessingState();
}

class RoutesBackupOkState extends RoutesBackupState {
  final int count;

  RoutesBackupOkState(this.count);
}

class RoutesBackupErrorState extends RoutesBackupState {
  GlobalException exception;

  RoutesBackupErrorState(this.exception);
}

//------------------------- DELETE -------------------------\\
abstract class RoutesDeleteState extends RoutesState {
  RoutesDeleteState();
}

class RoutesDeleteProcessingState extends RoutesDeleteState {
  RoutesDeleteProcessingState();
}

class RoutesDeleteOkState extends RoutesDeleteState {
  final String name;

  RoutesDeleteOkState(this.name);
}

class RoutesDeleteErrorState extends RoutesDeleteState {
  GlobalException exception;

  RoutesDeleteErrorState(this.exception);
}

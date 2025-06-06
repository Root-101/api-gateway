import 'dart:convert';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesCubit extends Cubit<RoutesState>
    with GlobalEventBusCommunication<RoutesState> {
  final AuthCubit auth;
  final RoutesRepo repo;

  RoutesCubit({required this.repo, required this.auth})
    : super(const RoutesInitialState()) {
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
    emit(const RoutesInitialState());
  }

  Future search({bool emitLoading = true}) async {
    try {
      //if there is a delete, create, restore, don't show the loading, just add/remove the route
      if (emitLoading) {
        emit(RoutesSearchingState());
      }

      List<RouteModel> routes = await repo.findAll(credential: auth.current);

      emit(RoutesSearchOkState(routes: routes));
    } on Exception catch (exc) {
      emit(RoutesSearchErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future delete({required RouteModel route}) async {
    try {
      emit(RoutesDeleteProcessingState());

      await repo.delete(credential: auth.current, route: route);

      emit(RoutesDeleteOkState());
    } on Exception catch (exc) {
      emit(RoutesDeleteErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future backup() async {
    try {
      emit(RoutesBackupProcessingState());

      List<RouteModel> routes = await repo.findAll(credential: auth.current);
      final encoder = const JsonEncoder.withIndent('  ');
      String rawData = encoder.convert(routes.map((e) => e.toJson()).toList());
      ExportDocument.downloadDocument(rawData);

      emit(RoutesBackupOkState());
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
  RoutesBackupOkState();
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
  RoutesDeleteOkState();
}

class RoutesDeleteErrorState extends RoutesDeleteState {
  GlobalException exception;

  RoutesDeleteErrorState(this.exception);
}

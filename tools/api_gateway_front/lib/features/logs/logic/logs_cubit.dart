import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogsCubit extends Cubit<LogsState>
    with GlobalEventBusCommunication<LogsState> {
  final AuthCubit auth;

  LogsCubit({required this.auth}) : super(const LogsInitialState());

  void reset() {
    emit(const LogsInitialState());
  }

  Future search({bool emitLoading = true}) async {
    try {
      if (emitLoading) {
        emit(LogsSearchingState());
      }

      await Future.delayed(Duration(seconds: 2));

      List<RouteModel> logs = [];

      emit(LogsSearchOkState(logs: logs));
    } on Exception catch (exc) {
      emit(LogsSearchErrorState(ExceptionConverter.parse(exc)));
    }
  }
}

abstract class LogsState {
  const LogsState();
}

class LogsInitialState extends LogsState {
  const LogsInitialState();
}

//------------------------- SEARCH -------------------------\\
abstract class LogsSearchState extends LogsState {
  LogsSearchState();
}

class LogsSearchingState extends LogsSearchState {
  LogsSearchingState();
}

class LogsSearchOkState extends LogsSearchState {
  final List<RouteModel> logs;

  LogsSearchOkState({required this.logs});
}

class LogsSearchErrorState extends LogsSearchState {
  GlobalException exception;

  LogsSearchErrorState(this.exception);
}

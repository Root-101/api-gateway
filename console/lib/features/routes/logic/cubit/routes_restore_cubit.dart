import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesRestoreCubit extends Cubit<RoutesRestoreState>
    with GlobalEventBusCommunication<RoutesRestoreState> {
  final RoutesRepo repo;

  RoutesRestoreCubit({required this.repo})
    : super(const RoutesRestoreInitialState());

  Future restore({required String rawFileContent}) async {
    try {
      emit(RoutesRestoreProcessingState());

      await repo.restore(rawFileContent: rawFileContent);

      emit(RoutesRestoreOkState(repo.parseBackup(rawFileContent).length));
    } on Exception catch (exc) {
      emit(RoutesRestoreErrorState(ExceptionConverter.parse(exc)));
    }
  }
}

abstract class RoutesRestoreState {
  const RoutesRestoreState();
}

class RoutesRestoreInitialState extends RoutesRestoreState {
  const RoutesRestoreInitialState();
}

class RoutesRestoreProcessingState extends RoutesRestoreState {
  RoutesRestoreProcessingState();
}

class RoutesRestoreOkState extends RoutesRestoreState {
  final int count;

  RoutesRestoreOkState(this.count);
}

class RoutesRestoreErrorState extends RoutesRestoreState {
  GlobalException exception;

  RoutesRestoreErrorState(this.exception);
}

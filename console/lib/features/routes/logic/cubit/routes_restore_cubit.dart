import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesRestoreCubit extends Cubit<RoutesRestoreState>
    with GlobalEventBusCommunication<RoutesRestoreState> {
  final RoutesRepo repo;

  RoutesRestoreCubit({required this.repo})
    : super(const RoutesRestoreInitialState());

  Future restore({required String rawFileContent}) async {
    try {
      emit(RoutesRestoringState());

      await repo.restore(rawFileContent: rawFileContent);

      emit(RoutesRestoredOkState(repo.parseBackup(rawFileContent).length));
    } on Exception catch (exc) {
      emit(RoutesRestoringErrorState(ExceptionConverter.parse(exc)));
    }
  }
}

abstract class RoutesRestoreState {
  const RoutesRestoreState();
}

final class RoutesRestoreInitialState extends RoutesRestoreState {
  const RoutesRestoreInitialState();
}

final class RoutesRestoringState extends RoutesRestoreState {
  RoutesRestoringState();
}

final class RoutesRestoredOkState extends RoutesRestoreState {
  final int count;

  RoutesRestoredOkState(this.count);
}

final class RoutesRestoringErrorState extends RoutesRestoreState {
  GlobalException exception;

  RoutesRestoringErrorState(this.exception);
}

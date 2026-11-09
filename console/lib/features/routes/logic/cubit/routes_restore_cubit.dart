import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesRestoreCubit extends Cubit<RoutesRestoreState>
    with GlobalEventBusCommunication<RoutesRestoreState> {
  final AuthCubit auth;
  final RoutesRepo repo;

  RoutesRestoreCubit({required this.repo, required this.auth})
    : super(const RoutesRestoreInitialState());

  Future restore({required String rawFileContent}) async {
    try {
      emit(RoutesRestoreProcessingState());

      await repo.restore(
        credential: auth.current,
        rawFileContent: rawFileContent,
      );

      emit(RoutesRestoreOkState());
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
  RoutesRestoreOkState();
}

class RoutesRestoreErrorState extends RoutesRestoreState {
  GlobalException exception;

  RoutesRestoreErrorState(this.exception);
}

import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum RoutesFormAction { create, edit, duplicate }

class RoutesFormCubit extends Cubit<RoutesFormState>
    with GlobalEventBusCommunication<RoutesFormState> {
  final RoutesRepo repo;

  final RoutesFormAction action;

  final String? paramRouteId;
  final RouteModel? paramRouteModel;

  late final String routeId;
  late final RouteModel routeModel;
  late final String gatewayUrl;

  RoutesFormCubit({
    required this.action,
    required this.repo,
    this.paramRouteId,
    this.paramRouteModel,
  }) : super(const RoutesFormInitialState()) {
    init();
  }

  Future init() async {
    emit(RoutesFormLoadingInProgressState());
    gatewayUrl = Environment.gatewayUrl;

    if (action == RoutesFormAction.create) {
      emit(
        RoutesFormLoadingSuccessState(action: action, gatewayUrl: gatewayUrl),
      );
    } else if (action == RoutesFormAction.edit ||
        action == RoutesFormAction.duplicate) {
      try {
        if (paramRouteId == null) {
          emit(RoutesFormLoadingErrorState(app.intl.errors.errorWrongRouteId));
          return;
        }
        routeId = paramRouteId!;

        if (paramRouteModel == null || paramRouteModel!.id != routeId) {
          routeModel = await repo.details(routeId: routeId);
        } else {
          routeModel = paramRouteModel!;
        }

        emit(
          RoutesFormLoadingSuccessState(
            routeModel: routeModel,
            action: action,
            gatewayUrl: gatewayUrl,
          ),
        );
      } on GlobalException catch (global) {
        emit(
          RoutesFormLoadingErrorState(
            app.intl.errors.errorLoadingRoute(message: global.intlMessage),
          ),
        );
      } on Exception {
        emit(RoutesFormLoadingErrorState(app.intl.errors.genericError));
      }
    } else {
      emit(RoutesFormLoadingErrorState(app.intl.errors.errorUnsupportedAction));
    }
  }

  ///the fields the api rejects, without saving; a [GlobalException] when it couldn't be checked
  Future<Map<String, String>> validate({required RouteFormModel model}) =>
      repo.validate(model: model);

  Future create({required RouteFormModel model}) async {
    emit(RoutesFormProcessInProgressState());
    try {
      await repo.create(model: model);

      emit(RoutesFormProcessingOKState(model.name, created: true));
    } on GlobalException catch (global) {
      if (global.type == GlobalExceptionType.validation &&
          global.data is List<ValidationError>) {
        emit(
          RoutesFormValidationErrorState(
            (global.data as List<ValidationError>).asFailedValidations(),
            action: action,
            gatewayUrl: gatewayUrl,
          ),
        );
      } else {
        emit(RoutesFormProcessingErrorState(global));
      }
    }
  }

  Future edit({required RouteFormModel model}) async {
    emit(RoutesFormProcessInProgressState());
    try {
      await repo.edit(routeId: routeId, model: model);

      emit(RoutesFormProcessingOKState(model.name, created: false));
    } on GlobalException catch (global) {
      if (global.type == GlobalExceptionType.validation &&
          global.data is List<ValidationError>) {
        emit(
          RoutesFormValidationErrorState(
            (global.data as List<ValidationError>).asFailedValidations(),
            action: action,
            routeModel: routeModel,
            gatewayUrl: gatewayUrl,
          ),
        );
      } else {
        emit(RoutesFormProcessingErrorState(global));
      }
    }
  }
}

abstract class RoutesFormState {
  const RoutesFormState();
}

final class RoutesFormInitialState extends RoutesFormState {
  const RoutesFormInitialState();
}

//----------------- loading -----------------\\
abstract class RoutesFormLoadingState extends RoutesFormState {
  RoutesFormLoadingState();
}

final class RoutesFormLoadingInProgressState extends RoutesFormLoadingState {
  RoutesFormLoadingInProgressState();
}

final class RoutesFormLoadingSuccessState extends RoutesFormLoadingState {
  final RoutesFormAction action;
  final RouteModel? routeModel;
  final String gatewayUrl;

  RoutesFormLoadingSuccessState({
    required this.action,
    required this.gatewayUrl,
    this.routeModel,
  });
}

final class RoutesFormValidationErrorState
    extends RoutesFormLoadingSuccessState {
  final Map<String, String>? failValidations;

  RoutesFormValidationErrorState(
    this.failValidations, {
    required super.action,
    required super.gatewayUrl,
    super.routeModel,
  });
}

final class RoutesFormLoadingErrorState extends RoutesFormLoadingState {
  final String text;

  RoutesFormLoadingErrorState(this.text);
}

//----------------- form -----------------\\
abstract class RoutesFormProcessState extends RoutesFormState {}

final class RoutesFormProcessInProgressState extends RoutesFormProcessState {
  RoutesFormProcessInProgressState();
}

final class RoutesFormProcessingOKState extends RoutesFormProcessState {
  final String name;
  final bool created;

  RoutesFormProcessingOKState(this.name, {required this.created});
}

final class RoutesFormProcessingErrorState extends RoutesFormProcessState {
  final GlobalException exception;

  RoutesFormProcessingErrorState(this.exception);
}

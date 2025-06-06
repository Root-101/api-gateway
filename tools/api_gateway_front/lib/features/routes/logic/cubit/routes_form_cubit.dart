import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum RoutesFormAction { create, edit, duplicate }

class RoutesFormCubit extends Cubit<RoutesFormState>
    with GlobalEventBusCommunication<RoutesFormState> {
  final AuthCubit auth;
  final RoutesRepo repo;

  final RoutesFormAction action;

  final String? paramRouteId;
  final RouteModel? paramRouteModel;

  late final String routeId;
  late final RouteModel routeModel;
  late final String gatewayUrl;

  RoutesFormCubit({
    required this.action,
    required this.auth,
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
          emit(RoutesFormLoadingErrorState('Wrong Route id'));
          return;
        }
        routeId = paramRouteId!;

        if (paramRouteModel == null || paramRouteModel!.id != routeId) {
          routeModel = await repo.details(
            credential: auth.current,
            routeId: routeId,
          );
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
            'Error loading Routes with id $routeId. ${global.message}',
          ),
        );
      } on Exception {
        emit(RoutesFormLoadingErrorState('Unknown error loading Routes'));
      }
    } else {
      RoutesFormLoadingErrorState('Accediendo a estado no soportado...');
    }
  }

  Future create({required RouteFormModel model}) async {
    emit(RoutesFormProcessInProgressState());
    try {
      await repo.create(credential: auth.current, model: model);

      emit(RoutesFormProcessingOKState());
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
      await repo.edit(credential: auth.current, routeId: routeId, model: model);

      emit(RoutesFormProcessingOKState());
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

class RoutesFormInitialState extends RoutesFormState {
  const RoutesFormInitialState();
}

//----------------- loading -----------------\\
abstract class RoutesFormLoadingState extends RoutesFormInitialState {
  RoutesFormLoadingState();
}

class RoutesFormLoadingInProgressState extends RoutesFormLoadingState {
  RoutesFormLoadingInProgressState();
}

class RoutesFormLoadingSuccessState extends RoutesFormLoadingState {
  final RoutesFormAction action;
  final RouteModel? routeModel;
  final String gatewayUrl;

  RoutesFormLoadingSuccessState({
    required this.action,
    required this.gatewayUrl,
    this.routeModel,
  });
}

class RoutesFormValidationErrorState extends RoutesFormLoadingSuccessState {
  final Map<String, String>? failValidations;

  RoutesFormValidationErrorState(
    this.failValidations, {
    required super.action,
    required super.gatewayUrl,
    super.routeModel,
  });
}

class RoutesFormLoadingErrorState extends RoutesFormLoadingState {
  final String text;

  RoutesFormLoadingErrorState(this.text);
}

//----------------- form -----------------\\
abstract class RoutesFormProcessState extends RoutesFormInitialState {}

class RoutesFormProcessInProgressState extends RoutesFormProcessState {
  RoutesFormProcessInProgressState();
}

class RoutesFormProcessingOKState extends RoutesFormProcessState {
  RoutesFormProcessingOKState();
}

class RoutesFormProcessingErrorState extends RoutesFormProcessState {
  final GlobalException exception;

  RoutesFormProcessingErrorState(this.exception);
}

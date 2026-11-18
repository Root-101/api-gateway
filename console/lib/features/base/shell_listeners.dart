import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///what the shell listens to, being the one always there: the add-ons' snacks (a panel, the banner
///or a card changed one) and the gateway coming back, which reloads what is on screen.
///No loading overlay: the slides and the panels show their own progress
class ShellListeners extends StatelessWidget {
  final Widget child;

  const ShellListeners({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GatewayStatusCubit, GatewayStatus>(
          listenWhen: (previous, current) =>
              previous.offline != current.offline,
          listener: _onGatewayChange,
        ),
        BlocListener<MaintenanceCubit, MaintenanceState>(
          listener: _onMaintenance,
        ),
        BlocListener<HealthCheckCubit, HealthCheckState>(
          listener: _onHealthCheck,
        ),
        BlocListener<RateLimitCubit, RateLimitState>(listener: _onRateLimit),
      ],
      child: child,
    );
  }

  void _onGatewayChange(BuildContext context, GatewayStatus status) {
    if (status.offline) return;
    app.snack.showSuccess(message: context.intl.offline.restored);
    app.di.find<RoutesCubit>().search(emitLoading: false);
    app.di.find<MaintenanceCubit>().load();
    app.di.find<RateLimitCubit>().load();
    final logs = app.di.find<LogsCubit>();
    if (logs.state is! LogsInitialState) logs.search();
  }

  void _onMaintenance(BuildContext context, MaintenanceState state) {
    final intl = context.intl.maintenance;
    if (state is MaintenanceSaveOkState) {
      final name = state.route?.name;
      app.snack.showSuccess(
        message: switch (state.action) {
          MaintenanceAction.added =>
            name == null ? intl.gatewayAdded : intl.added(name: name),
          MaintenanceAction.saved =>
            name == null ? intl.gatewaySaved : intl.saved(name: name),
          MaintenanceAction.enabled =>
            name == null ? intl.gatewayOn : intl.routeOn(name: name),
          MaintenanceAction.disabled =>
            name == null ? intl.gatewayOff : intl.routeOff(name: name),
          MaintenanceAction.deleted =>
            name == null ? intl.gatewayRemoved : intl.removed(name: name),
        },
      );
    } else if (state is MaintenanceSaveErrorState &&
        state.exception.type != GlobalExceptionType.validation) {
      //a 422 is shown under its field, in the panel
      app.snack.showError(message: state.message);
    }
  }

  void _onHealthCheck(BuildContext context, HealthCheckState state) {
    final intl = context.intl.health;
    if (state is HealthCheckSaveOkState) {
      final name = state.route.name;
      final message = switch (state.action) {
        HealthCheckAction.added => intl.added(name: name),
        HealthCheckAction.saved => intl.saved(name: name),
        HealthCheckAction.enabled => intl.routeOn(name: name),
        HealthCheckAction.disabled => intl.routeOff(name: name),
        HealthCheckAction.deleted => intl.removed(name: name),
        //the block shows the result
        HealthCheckAction.checked => null,
      };
      if (message != null) app.snack.showSuccess(message: message);
    } else if (state is HealthCheckSaveErrorState &&
        state.exception.type != GlobalExceptionType.validation) {
      app.snack.showError(message: state.message);
    }
  }

  void _onRateLimit(BuildContext context, RateLimitState state) {
    final intl = context.intl.rate;
    if (state is RateLimitSaveOkState) {
      final name = state.route?.name;
      app.snack.showSuccess(
        message: switch (state.action) {
          RateLimitAction.added =>
            name == null ? intl.gatewayAdded : intl.added(name: name),
          RateLimitAction.saved =>
            name == null ? intl.gatewaySaved : intl.saved(name: name),
          RateLimitAction.enabled =>
            name == null ? intl.gatewayOn : intl.routeOn(name: name),
          RateLimitAction.disabled =>
            name == null ? intl.gatewayOff : intl.routeOff(name: name),
          RateLimitAction.deleted =>
            name == null ? intl.gatewayRemoved : intl.removed(name: name),
        },
      );
    } else if (state is RateLimitSaveErrorState &&
        state.exception.type != GlobalExceptionType.validation) {
      app.snack.showError(message: state.message);
    }
  }
}

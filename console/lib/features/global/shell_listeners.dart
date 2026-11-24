import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///what the shell listens to, being the one always there: the add-ons' toasts (a panel, the banner
///or a card changed one) and the gateway coming back, which reloads what is on screen.
///No loading overlay: the slides and the panels show their own progress
class ShellListeners extends StatelessWidget {
  final Widget child;

  const ShellListeners({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GatewayStatusCubit, GatewayStatusState>(
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
        BlocListener<CorsCubit, CorsState>(listener: _onCors),
      ],
      child: child,
    );
  }

  void _onGatewayChange(BuildContext context, GatewayStatusState status) {
    if (status.offline) return;
    app.toast.success(context.intl.offline.restored);
    app.di.find<RoutesCubit>().search(emitLoading: false);
    app.di.find<MaintenanceCubit>().load();
    app.di.find<RateLimitCubit>().load();
    app.di.find<CorsCubit>().load();
    final logs = app.di.find<LogsCubit>();
    if (logs.state is! LogsInitialState) logs.search();
  }

  void _onMaintenance(BuildContext context, MaintenanceState state) {
    final intl = context.intl.maintenance;
    if (state is MaintenanceSavedOkState) {
      final name = state.route?.name;
      app.toast.success(switch (state.action) {
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
      });
    } else if (state is MaintenanceSavingErrorState &&
        state.exception.type != GlobalExceptionType.validation) {
      //a 422 is shown under its field, in the panel
      app.toast.error(state.message);
    }
  }

  void _onHealthCheck(BuildContext context, HealthCheckState state) {
    final intl = context.intl.health;
    if (state is HealthCheckSavedOkState) {
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
      if (message != null) app.toast.success(message);
    } else if (state is HealthCheckSavingErrorState &&
        state.exception.type != GlobalExceptionType.validation) {
      app.toast.error(state.message);
    }
  }

  void _onRateLimit(BuildContext context, RateLimitState state) {
    final intl = context.intl.rate;
    if (state is RateLimitSavedOkState) {
      final name = state.route?.name;
      app.toast.success(switch (state.action) {
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
      });
    } else if (state is RateLimitSavingErrorState &&
        state.exception.type != GlobalExceptionType.validation) {
      app.toast.error(state.message);
    }
  }

  void _onCors(BuildContext context, CorsState state) {
    final intl = context.intl.cors;
    if (state is CorsSavedOkState) {
      final name = state.route?.name;
      app.toast.success(switch (state.action) {
        CorsAction.added => intl.added(name: name ?? ''),
        CorsAction.saved =>
          name == null ? intl.gatewaySaved : intl.saved(name: name),
        CorsAction.enabled => intl.routeOn(name: name ?? ''),
        CorsAction.disabled => intl.routeOff(name: name ?? ''),
        CorsAction.deleted => intl.removed(name: name ?? ''),
      });
    } else if (state is CorsSavingErrorState && !state.shownInBlock) {
      app.toast.error(state.message);
    }
  }
}

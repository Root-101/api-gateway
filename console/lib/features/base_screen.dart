import 'dart:async';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

///shell of the logged-in screens: collapsible rail + content (with the offline and maintenance
///banners on top). It loads the gateway's add-ons and polls the health checks; [ShellListeners]
///shows the snacks, [AppRail] and the banners are widgets of their own
class BaseScreen extends StatefulWidget {
  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  const BaseScreen(this.navigationShell, {super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  final MaintenanceCubit _maintenance = app.di.find();

  ///the gateway writes each health check's result on its own (no push): reread the routes
  Timer? _healthPoll;

  @override
  void initState() {
    super.initState();
    _maintenance.load();
    app.di.find<RateLimitCubit>().load();
    _healthPoll = Timer.periodic(const Duration(seconds: 10), (_) {
      final routes = app.di.find<RoutesCubit>();
      if (app.di.find<GatewayStatusCubit>().state.offline ||
          !routes.routes.any((r) => r.healthCheck?.enabled ?? false)) {
        return;
      }
      routes.search(emitLoading: false);
    });
  }

  @override
  void dispose() {
    _healthPoll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    return ShellListeners(
      child: Scaffold(
        body: Row(
          children: [
            AppRail(currentIndex: shell.currentIndex, onSelect: shell.goBranch),
            Expanded(
              child: GridBackground(
                child: BlocBuilder<GatewayStatusCubit, GatewayStatus>(
                  buildWhen: (previous, current) =>
                      previous.offline != current.offline ||
                      previous.retrying != current.retrying,
                  builder: (context, status) => Column(
                    children: [
                      if (status.offline) OfflineBanner(status),
                      BlocBuilder<MaintenanceCubit, MaintenanceState>(
                        builder: (context, _) => _maintenance.gatewayOn
                            ? MaintenanceBanner(_maintenance.gateway!)
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: IgnorePointer(
                          ignoring: status.offline,
                          child: AnimatedOpacity(
                            opacity: status.offline ? 0.55 : 1,
                            duration: motion(
                              context,
                              const Duration(milliseconds: 200),
                            ),
                            child: shell,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

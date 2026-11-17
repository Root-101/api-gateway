import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/addons/maintenance_block.dart';
import 'package:console/features/routes/view/form/routes_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///what a route shows by its name: the gateway's maintenance wins over its own
enum RouteStatus {
  paused,
  maintenance,
  none;

  static RouteStatus of(RouteModel route, {required bool gatewayOn}) =>
      gatewayOn
      ? paused
      : route.inMaintenance
      ? maintenance
      : none;
}

///PAUSED / MAINT pill next to a name
class StatusTag extends StatelessWidget {
  final RouteStatus status;

  const StatusTag(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    if (status == RouteStatus.none) return const SizedBox.shrink();
    final c = app.colors;
    final intl = context.intl;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.maintenance.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: c.maintenance,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status == RouteStatus.paused
                ? intl.maintenance.tagPaused
                : intl.maintenance.tagMaint,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: c.maintenance,
            ),
          ),
        ],
      ),
    );
  }
}

///the side panel of a route (or of the gateway, [routeId] null), shared by the map and Routes:
///its redirect, its add-ons and the ones it can still get. Reads the route from [RoutesCubit],
///so it always shows what was saved last
class RoutePanel extends StatelessWidget {
  final String? routeId;
  final VoidCallback onClose;

  ///"Open in Routes" on the map, "Edit route" in Routes
  final String redirectLabel;
  final void Function(RouteModel route) onRedirect;

  const RoutePanel({
    required this.routeId,
    required this.onClose,
    required this.redirectLabel,
    required this.onRedirect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutesCubit, RoutesState>(
      buildWhen: (previous, current) => current is RoutesSearchState,
      builder: (context, _) => BlocBuilder<MaintenanceCubit, MaintenanceState>(
        builder: (context, _) {
          final maintenance = app.di.find<MaintenanceCubit>();
          final routes = app.di.find<RoutesCubit>().routes;
          RouteModel? route;
          if (routeId != null) {
            for (final r in routes) {
              if (r.id == routeId) route = r;
            }
            //deleted meanwhile
            if (route == null) return const SizedBox.shrink();
          }
          return _build(context, route, maintenance);
        },
      ),
    );
  }

  Widget _build(
    BuildContext context,
    RouteModel? route,
    MaintenanceCubit maintenance,
  ) {
    final c = app.colors;
    final intl = context.intl;
    final gatewayOn = maintenance.gatewayOn;
    final own = route == null ? maintenance.gateway : route.maintenance;
    final status = route == null
        ? (gatewayOn ? RouteStatus.maintenance : RouteStatus.none)
        : RouteStatus.of(route, gatewayOn: gatewayOn);
    return Material(
      color: c.surface,
      elevation: 16,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.outlineCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.outlineCard)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaptionText(
                        route == null ? intl.panel.gateway : intl.panel.route,
                        size: 11,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          route == null
                              ? Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'api',
                                        style: TextStyle(color: c.lilac),
                                      ),
                                      const TextSpan(text: '-gateway'),
                                    ],
                                  ),
                                  style: monoStyle(
                                    size: 19,
                                    weight: FontWeight.w500,
                                    color: c.text,
                                  ),
                                )
                              : Text(
                                  route.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    height: 26 / 20,
                                    fontWeight: FontWeight.w500,
                                    color: c.text,
                                  ),
                                ),
                          StatusTag(status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route == null
                            ? intl.panel.gatewayDescription
                            : route.description.isEmpty
                            ? intl.routes.noDescription
                            : route.description,
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: app.assets.icons.actions.close,
                  tooltip: intl.actions.close,
                  size: 40,
                  iconSize: 18,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (route != null) ...[
                    _RedirectBlock(
                      route: route,
                      label: redirectLabel,
                      onPressed: () => onRedirect(route),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    _EntryBlock(url: Environment.gatewayUrl),
                    const SizedBox(height: 12),
                  ],
                  if (own != null)
                    MaintenanceBlock(
                      key: ValueKey('maint-${route?.id ?? 'gateway'}'),
                      route: route,
                      model: own,
                      locked: route != null && gatewayOn,
                    )
                  else ...[
                    const SizedBox(height: 6),
                    CaptionText(
                      route == null
                          ? intl.panel.addToGateway
                          : intl.panel.addToRoute,
                      size: 11,
                    ),
                    const SizedBox(height: 8),
                    _AddTile(
                      onPressed: () => app.di.find<MaintenanceCubit>().put(
                        route: route,
                        action: MaintenanceAction.added,
                        //off with the gateway's default message: ready to edit
                        model: MaintenanceModel(enabled: false),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedirectBlock extends StatelessWidget {
  final RouteModel route;
  final String label;
  final VoidCallback onPressed;

  const _RedirectBlock({
    required this.route,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              app.assets.icons.actions.arrowRight.build(
                size: 17,
                color: c.label,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  intl.panel.redirect,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
              ),
              AppButton(
                label: label,
                kind: AppButtonKind.outlined,
                height: 34,
                fontSize: 13,
                onPressed: onPressed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: c.night,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.outlineSoft),
            ),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RouteUrlBlock(
                    caption: intl.routes.from,
                    url: route.enterPoint,
                    fontSize: 12,
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: c.outlineSoft,
                  ),
                  RouteUrlBlock(
                    caption: intl.routes.to,
                    url: route.redirectTo,
                    accent: true,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///the gateway's own block: the url every request comes in by
class _EntryBlock extends StatelessWidget {
  final String url;

  const _EntryBlock({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.night,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outlineSoft),
      ),
      child: SelectionArea(
        child: RouteUrlBlock(
          caption: context.intl.routes.from,
          url: url,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddTile({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.outlineCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.maintenance.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: app.assets.icons.general.wrench.build(
                  size: 16,
                  color: c.maintenance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intl.panel.addMaintenance,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.text,
                      ),
                    ),
                    Text(
                      intl.panel.addMaintenanceHint,
                      style: TextStyle(fontSize: 12, color: c.textTertiary),
                    ),
                  ],
                ),
              ),
              app.assets.icons.actions.add.build(size: 18, color: c.lilac),
            ],
          ),
        ),
      ),
    );
  }
}

///the panel as a sheet on the right of the screen (Routes; the map shows it inside its canvas)
class RoutePanelSheet {
  static Future<void> show(BuildContext context, RouteModel route) {
    return app.dialog.open(
      context: context,
      dialog: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 380,
            child: Builder(
              builder: (context) => RoutePanel(
                routeId: route.id,
                redirectLabel: context.intl.panel.editRoute,
                onClose: () => Navigator.of(context).pop(),
                onRedirect: (route) {
                  Navigator.of(context).pop();
                  RoutesFormScreen.navigator.edit(model: route);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

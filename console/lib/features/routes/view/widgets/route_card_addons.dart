import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///a badge per add-on of the route, then + Add-ons; both open the route's panel
class RouteCardAddons extends StatelessWidget {
  final RouteModel route;

  const RouteCardAddons({required this.route, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final maintenance = route.maintenance;
    final health = route.healthCheck;
    void open() => RoutePanelSheet.show(context, route);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (health != null)
          RouteBadge(
            icon: app.assets.icons.general.activity,
            label: health.enabled
                ? intl.health.badge(time: intervalText(health.intervalSeconds))
                : intl.health.badgeOff,
            color: health.down ? c.dangerText : c.label,
            onPressed: open,
          ),
        if (maintenance != null)
          RouteBadge(
            icon: app.assets.icons.general.wrench,
            label: maintenance.enabled
                ? intl.maintenance.badgeOn
                : intl.maintenance.badgeOff,
            color: maintenance.enabled ? c.maintenance : c.label,
            onPressed: open,
          ),
        if (route.rateLimit case final rate?)
          RouteBadge(
            icon: app.assets.icons.general.gauge,
            label: rate.enabled
                ? intl.rate.badge(value: rateShort(rate))
                : intl.rate.badgeOff,
            color: rate.enabled ? c.info : c.label,
            onPressed: open,
          ),
        RouteBadge(
          icon: app.assets.icons.actions.add,
          label: intl.maintenance.addons,
          color: c.label,
          dashed: true,
          onPressed: open,
        ),
      ],
    );
  }
}

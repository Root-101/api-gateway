import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class MapRouteNode extends StatelessWidget {
  final RouteModel route;
  final bool gatewayOn;
  final bool selected;
  final VoidCallback onTap;

  const MapRouteNode({
    required this.route,
    required this.gatewayOn,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final status = RouteStatus.of(route, gatewayOn: gatewayOn);
    final ownOn = status == RouteStatus.maintenance;
    final maintenance = route.maintenance;
    final health = route.healthCheck;
    final rate = route.rateLimit;
    final cors = route.cors;
    final host = Uri.tryParse(route.uri)?.host;
    return MapNode(
      onTap: onTap,
      selected: selected,
      dashed: ownOn,
      background: ownOn
          ? const Color(0xff221b1f)
          : status == RouteStatus.down
          ? const Color(0xff1f1519)
          : c.card,
      border: ownOn
          ? c.maintenance
          : status == RouteStatus.down
          ? c.danger.withValues(alpha: 0.6)
          : c.outlineCard,
      //paused by the gateway's maintenance too: its branch is orange, so is the selection
      selectedBorder: status.inMaintenance
          ? c.maintenance
          : status == RouteStatus.down
          ? c.danger
          : null,
      semanticLabel: '${route.name} ${route.path}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: c.text,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                StatusTag(status),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              route.description.isEmpty
                  ? intl.routes.noDescription
                  : route.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: route.description.isEmpty
                    ? c.textTertiary
                    : c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '→ ${host == null || host.isEmpty ? route.uri : host}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(size: 12, color: c.label),
            ),
            const Spacer(),
            Container(height: 1, color: c.outlineSoft),
            const SizedBox(height: 8),
            if (maintenance == null &&
                health == null &&
                rate == null &&
                cors == null)
              Text(
                intl.maintenance.redirectOnly,
                style: TextStyle(fontSize: 12, color: c.textTertiary),
              )
            else
              Row(
                children: [
                  if (health != null) ...[
                    MapChip(
                      icon: app.assets.icons.general.activity,
                      color: health.down ? c.dangerText : null,
                      label: health.enabled
                          ? intervalText(health.intervalSeconds)
                                .replaceAll(' ', '')
                          : intl.maintenance.chipOff,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (maintenance != null) ...[
                    MapChip(
                      icon: app.assets.icons.general.wrench,
                      color: maintenance.enabled ? c.maintenance : null,
                      label: maintenance.enabled
                          ? intl.maintenance.chipOn
                          : intl.maintenance.chipOff,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (rate != null) ...[
                    MapChip(
                      icon: app.assets.icons.general.gauge,
                      color: null,
                      label: rate.enabled
                          ? rateShort(rate)
                          : intl.maintenance.chipOff,
                    ),
                    const SizedBox(width: 6),
                  ],
                  //icon only: the card has no room for a fourth label
                  if (cors != null)
                    Tooltip(
                      message: cors.enabled
                          ? intl.cors.badge(value: corsShort(context, cors))
                          : intl.cors.badgeOff,
                      child: MapChip(
                        icon: app.assets.icons.general.globe,
                        color: cors.enabled ? c.lilac : null,
                        label: '',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class MapGatewayNode extends StatelessWidget {
  final List<RouteModel> routes;
  final MaintenanceModel? maintenance;
  final bool selected;
  final VoidCallback onTap;

  const MapGatewayNode({
    required this.routes,
    required this.maintenance,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final on = maintenance?.enabled ?? false;
    final count = routes.length;
    final routesText = count == 1
        ? intl.map.oneRoute
        : intl.map.manyRoutes(count: count);
    final inMaint = routes.where((r) => r.inMaintenance).length;
    return MapNode(
      onTap: onTap,
      selected: selected,
      dashed: on,
      background: on ? const Color(0xff221b1f) : c.surface,
      border: on ? c.maintenance : c.outline,
      selectedBorder: on ? c.maintenance : null,
      semanticLabel: 'api-gateway',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on
                          ? c.maintenance.withValues(alpha: 0.12)
                          : c.lilac.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: app.assets.icons.gateway.build(
                      size: 26,
                      color: on ? c.maintenance : c.lilac,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
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
                            color: c.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (on) ...[
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: c.maintenance,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Ticking(
                                  builder: (context) {
                                    final onFor = maintenance?.onFor;
                                    return Text(
                                      onFor == null
                                          ? intl.map.gatewayInMaintenance
                                          : '${intl.map.gatewayInMaintenance} · '
                                                '${durationText(onFor.inSeconds)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: c.maintenance,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            intl.map.gatewayAll(count: count),
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ] else
                          Text(
                            [
                              routesText,
                              if (inMaint > 0)
                                intl.maintenance.inCount(count: inMaint),
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: c.outlineSoft),
            const SizedBox(height: 8),
            //the gateway's add-ons live in other cubits: rebuild on their changes too
            BlocBuilder<RateLimitCubit, RateLimitState>(
              builder: (context, _) => BlocBuilder<CorsCubit, CorsState>(
                builder: (context, _) {
                  final rate = app.di.find<RateLimitCubit>().gateway;
                  final cors = app.di.find<CorsCubit>().gateway;
                  return Row(
                    spacing: 6,
                    children: [
                      if (maintenance != null)
                        MapChip(
                          icon: app.assets.icons.general.wrench,
                          color: on ? c.maintenance : null,
                          label: on
                              ? intl.maintenance.badgeOn
                              : intl.maintenance.badgeOff,
                        ),
                      if (rate != null)
                        MapChip(
                          icon: app.assets.icons.general.gauge,
                          color: rate.enabled ? c.info : null,
                          label: rate.enabled
                              ? intl.rate.badge(value: 'on')
                              : intl.rate.badgeOff,
                        ),
                      //always on, nothing to flag
                      if (cors != null)
                        MapChip(
                          icon: app.assets.icons.general.globe,
                          color: null,
                          label: intl.cors.title,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

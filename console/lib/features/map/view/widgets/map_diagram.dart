import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///what pans and zooms: the url, the gateway, a branch with its path per route and the route nodes
class MapDiagram extends StatelessWidget {
  final MapLayout layout;
  final List<RouteModel> routes;
  final bool loaded;
  final bool gatewayOn;
  final MaintenanceModel? gatewayMaintenance;

  ///the open panel: a route id, [GatewayMapScreen.gatewayId] or null
  final String? panelId;
  final Animation<double> flow;
  final ValueChanged<String> onSelect;

  const MapDiagram({
    required this.layout,
    required this.routes,
    required this.loaded,
    required this.gatewayOn,
    required this.gatewayMaintenance,
    required this.panelId,
    required this.flow,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selectedRoute = panelId == GatewayMapScreen.gatewayId
        ? null
        : panelId;
    final branches = [
      for (var i = 0; i < routes.length; i++)
        MapBranch(
          from: Offset(layout.startX(i), layout.gwBottom),
          to: Offset(layout.cardCenter(i), MapLayout.cardTop),
          status: RouteStatus.of(routes[i], gatewayOn: gatewayOn),
          dimmed: selectedRoute != null && routes[i].id != selectedRoute,
        ),
      if (routes.isEmpty && loaded)
        MapBranch(
          from: Offset(layout.cx, layout.gwBottom),
          to: Offset(layout.cx, MapLayout.cardTop),
          status: null,
          dimmed: false,
        ),
    ];
    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: MapBranchesPainter(
                branches: branches,
                entry: Offset(layout.cx, MapLayout.urlH),
                entryEnd: Offset(layout.cx, MapLayout.gwTop - 4),
                flow: flow,
                arrowColor: app.colors.textTertiary,
              ),
            ),
          ),
          Positioned(
            left: layout.cx - MapLayout.urlW / 2,
            top: 0,
            width: MapLayout.urlW,
            height: MapLayout.urlH,
            child: MapUrlNode(url: Environment.gatewayUrl),
          ),
          Positioned(
            left: layout.cx - MapLayout.gwW / 2,
            top: MapLayout.gwTop,
            width: MapLayout.gwW,
            height: MapLayout.gwH,
            child: MapGatewayNode(
              routes: routes,
              maintenance: gatewayMaintenance,
              selected: panelId == GatewayMapScreen.gatewayId,
              onTap: () => onSelect(GatewayMapScreen.gatewayId),
            ),
          ),
          for (var i = 0; i < routes.length; i++) ...[
            Positioned(
              left: (layout.startX(i) + layout.cardCenter(i)) / 2,
              top: layout.labelY,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: Opacity(
                  opacity: branches[i].dimmed ? 0.35 : 1,
                  child: MapPathLabel(
                    path: routes[i].path,
                    status: branches[i].status,
                  ),
                ),
              ),
            ),
            Positioned(
              left: layout.cardLeft(i),
              top: MapLayout.cardTop,
              width: MapLayout.cardW,
              height: MapLayout.cardH,
              child: Opacity(
                opacity: branches[i].dimmed ? 0.55 : 1,
                child: MapRouteNode(
                  route: routes[i],
                  gatewayOn: gatewayOn,
                  selected: routes[i].id == selectedRoute,
                  onTap: () => onSelect(routes[i].id),
                ),
              ),
            ),
          ],
          if (routes.isEmpty && loaded)
            Positioned(
              left: layout.cx - MapLayout.cardW / 2,
              top: MapLayout.cardTop,
              width: MapLayout.cardW,
              height: MapLayout.cardH,
              child: const MapAddRouteNode(),
            ),
        ],
      ),
    );
  }
}

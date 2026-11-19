import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GatewayMapScreenNavigator {
  String get name => 'map';

  String get path => '/map';

  Widget builder(BuildContext context, GoRouterState state) {
    return const GatewayMapScreen();
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
  }

  ///the map with the gateway's panel open (the banner's Edit)
  void openGateway() {
    GatewayMapScreen.selected.value = GatewayMapScreen.gatewayId;
    app.navigator.go(name);
  }
}

///the gateway as a diagram, its url on top, one branch per route below.
///A click on a node opens its panel on the right; drag to move, wheel to zoom
class GatewayMapScreen extends StatefulWidget {
  static final GatewayMapScreenNavigator navigator =
      GatewayMapScreenNavigator();

  static const String gatewayId = '#gateway';

  ///the node whose panel is open: a route id, [gatewayId] or null
  static final ValueNotifier<String?> selected = ValueNotifier(null);

  const GatewayMapScreen({super.key});

  @override
  State<GatewayMapScreen> createState() => _GatewayMapScreenState();
}

///the screen keeps the view (pan, zoom, fit) and the selection; [MapHeader] and [MapDiagram] draw it
class _GatewayMapScreenState extends State<GatewayMapScreen>
    with SingleTickerProviderStateMixin {
  static const double _panelW = 380;

  ///the big panel's widest, centered over the map
  static const double _bigW = 1180;
  static const Duration _morph = Duration(milliseconds: 360);
  final TransformationController _view = TransformationController();
  final ValueNotifier<bool> _grabbing = ValueNotifier(false);
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Size _viewport = Size.zero;
  bool _fitted = false;
  double _scale = 1;

  ///the panel open as the big one in the middle
  bool _big = false;

  RoutesCubit get _routes => app.di.find();

  @override
  void initState() {
    super.initState();
    if (_routes.state is RoutesInitialState) _routes.search();
    GatewayMapScreen.selected.addListener(_onSelected);
    _view.addListener(() {
      //the x scale: z stays at 1 when zooming out, so getMaxScaleOnAxis never goes below 1
      final s = _view.value.storage[0];
      if ((s - _scale).abs() > 0.001) setState(() => _scale = s);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _flow.stop();
    } else if (!_flow.isAnimating) {
      _flow.repeat();
    }
  }

  @override
  void dispose() {
    GatewayMapScreen.selected.removeListener(_onSelected);
    _view.dispose();
    _grabbing.dispose();
    _flow.dispose();
    super.dispose();
  }

  void _onSelected() {
    setState(() {
      if (GatewayMapScreen.selected.value == null) _big = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _keepVisible());
  }

  void _select(String? id) => GatewayMapScreen.selected.value =
      GatewayMapScreen.selected.value == id ? null : id;

  ///the panel covers the right of the canvas: move the selected card out from under it
  void _keepVisible() {
    final id = GatewayMapScreen.selected.value;
    if (id == null || id == GatewayMapScreen.gatewayId) return;
    final routes = _routes.routes;
    final i = routes.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final layout = MapLayout(routes.length);
    final right =
        (layout.cardLeft(i) + MapLayout.cardW) * _scale +
        _view.value.getTranslation().x;
    final limit = _viewport.width - _panelW - 32;
    if (right > limit) {
      _view.value = _view.value.clone()
        ..translateByDouble((limit - right) / _scale, 0, 0, 1);
    }
  }

  void _fit(MapLayout layout) {
    if (_viewport == Size.zero) return;
    final s = min(
      1.0,
      min(
        (_viewport.width - 48) / layout.width,
        (_viewport.height - 48) / layout.height,
      ),
    ).clamp(0.4, 1.0);
    final dx = (_viewport.width - layout.width * s) / 2;
    final dy = max(24.0, (_viewport.height - layout.height * s) / 2);
    _view.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  void _zoom(double factor) {
    final target = (_scale * factor).clamp(0.4, 2.0);
    final f = target / _scale;
    final center = Offset(_viewport.width / 2, _viewport.height / 2);
    _view.value = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(f, f, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1)
      ..multiply(_view.value);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutesCubit, RoutesState>(
      buildWhen: (previous, current) => current is RoutesSearchState,
      builder: (context, state) =>
          BlocBuilder<MaintenanceCubit, MaintenanceState>(
            builder: (context, _) {
              if (state is RoutesSearchErrorState && !_routes.loaded) {
                return ErrorPage(
                  errorMessage: state.exception.message,
                  buttonText: context.intl.actions.tryAgain,
                  onPressed: _routes.search,
                );
              }
              final layout = MapLayout(_routes.routes.length);
              return Column(
                children: [
                  MapHeader(
                    scale: _scale,
                    onZoom: _zoom,
                    onFit: () => _fit(layout),
                  ),
                  Expanded(child: _buildCanvas(context, layout)),
                ],
              );
            },
          ),
    );
  }

  Widget _buildCanvas(BuildContext context, MapLayout layout) {
    final c = app.colors;
    final intl = context.intl;
    final maintenance = app.di.find<MaintenanceCubit>();
    final routes = _routes.routes;
    final selected = GatewayMapScreen.selected.value;
    final panelId = selected == GatewayMapScreen.gatewayId
        ? GatewayMapScreen.gatewayId
        : routes.any((r) => r.id == selected)
        ? selected
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        final morph = MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : _morph;
        final bigInset = max(32.0, (constraints.maxWidth - _bigW) / 2);
        if (!_fitted && _routes.loaded) {
          _fitted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _fit(layout));
        }
        return Stack(
          children: [
            //the page grid, redrawn here so it pans and zooms with the map
            Positioned.fill(child: GridBackground(view: _view)),
            Positioned.fill(
              //drag hand over the canvas; nodes and buttons keep their own click cursor
              child: ValueListenableBuilder(
                valueListenable: _grabbing,
                builder: (context, grabbing, child) => MouseRegion(
                  cursor: grabbing
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab,
                  child: Listener(
                    onPointerDown: (_) => _grabbing.value = true,
                    onPointerUp: (_) => _grabbing.value = false,
                    onPointerCancel: (_) => _grabbing.value = false,
                    child: child,
                  ),
                ),
                child: InteractiveViewer(
                  transformationController: _view,
                  constrained: false,
                  minScale: 0.4,
                  maxScale: 2,
                  boundaryMargin: const EdgeInsets.all(2000),
                  child: GestureDetector(
                    //a click on the background closes the panel
                    onTap: () => GatewayMapScreen.selected.value = null,
                    child: MapDiagram(
                      layout: layout,
                      routes: routes,
                      loaded: _routes.loaded,
                      gatewayOn: maintenance.gatewayOn,
                      gatewayMaintenance: maintenance.gateway,
                      panelId: panelId,
                      flow: _flow,
                      onSelect: _select,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 12,
              child: Text(
                intl.map.hint,
                style: TextStyle(fontSize: 12, color: c.textTertiary),
              ),
            ),
            if (!_routes.loaded)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (panelId != null) ...[
              //the big panel's scrim: a click outside closes it
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_big,
                  child: GestureDetector(
                    onTap: () => GatewayMapScreen.selected.value = null,
                    child: AnimatedOpacity(
                      opacity: _big ? 1 : 0,
                      duration: morph,
                      child: ColoredBox(color: c.barrier),
                    ),
                  ),
                ),
              ),
              //the same four edges on the side and in the middle, so the box can animate
              AnimatedPositioned(
                duration: morph,
                curve: appEase,
                top: _big ? 40 : 12,
                bottom: _big ? 40 : 12,
                right: _big ? bigInset : 12,
                left: _big ? bigInset : constraints.maxWidth - 12 - _panelW,
                child: RoutePanel(
                  key: ValueKey(panelId),
                  routeId: panelId == GatewayMapScreen.gatewayId
                      ? null
                      : panelId,
                  redirectLabel: intl.panel.openInRoutes,
                  expanded: _big,
                  onExpand: () => setState(() => _big = !_big),
                  onClose: () => GatewayMapScreen.selected.value = null,
                  onRedirect: (route) {
                    _routes.query.value = route.name;
                    app.navigator.go(RoutesScreen.navigator.name);
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

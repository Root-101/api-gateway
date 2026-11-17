import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/routes_form_screen.dart';
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

class _Layout {
  static const double cardW = 248;
  static const double cardH = 140;
  static const double gap = 48;
  static const double urlW = 440;
  static const double urlH = 44;
  static const double gwW = 350;
  static const double gwH = 112;
  static const double gwTop = 92;
  static const double cardTop = 352;
  static const double margin = 120;

  final int count;
  late final double width = max(
    900,
    max(1, count) * cardW + (max(1, count) - 1) * gap + margin * 2,
  );
  final double height = cardTop + cardH + 40;

  _Layout(this.count);

  double get cx => width / 2;

  double get gwBottom => gwTop + gwH;

  double get labelY => (gwBottom + cardTop) / 2;

  double cardLeft(int i) {
    final n = max(1, count);
    final total = n * cardW + (n - 1) * gap;
    return cx - total / 2 + i * (cardW + gap);
  }

  double cardCenter(int i) => cardLeft(i) + cardW / 2;

  ///where branch [i] leaves the gateway node: spread along its bottom edge
  double startX(int i) =>
      cx + ((cardCenter(i) - cx) * 0.35).clamp(-gwW / 2 + 40, gwW / 2 - 40);
}

class _GatewayMapScreenState extends State<GatewayMapScreen>
    with SingleTickerProviderStateMixin {
  static const double _panelW = 380;
  final TransformationController _view = TransformationController();
  final ValueNotifier<bool> _grabbing = ValueNotifier(false);
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Size _viewport = Size.zero;
  bool _fitted = false;
  double _scale = 1;

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
    setState(() {});
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
    final layout = _Layout(routes.length);
    final right =
        (layout.cardLeft(i) + _Layout.cardW) * _scale +
        _view.value.getTranslation().x;
    final limit = _viewport.width - _panelW - 32;
    if (right > limit) {
      _view.value = _view.value.clone()
        ..translateByDouble((limit - right) / _scale, 0, 0, 1);
    }
  }

  void _fit(_Layout layout) {
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
              final layout = _Layout(_routes.routes.length);
              return Column(
                children: [
                  _buildHeader(context, layout),
                  Expanded(child: _buildCanvas(context, layout)),
                ],
              );
            },
          ),
    );
  }

  Widget _buildHeader(BuildContext context, _Layout layout) {
    final c = app.colors;
    final intl = context.intl;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.raised)),
      ),
      child: Row(
        children: [
          Text(
            intl.map.title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: c.text,
            ),
          ),
          const Spacer(),
          _LegendItem(
            label: intl.map.legendRedirect,
            color: _Branch.redirectColor,
            dash: const [6, 5],
          ),
          const SizedBox(width: 16),
          _LegendItem(
            label: intl.map.legendMaintenance,
            color: c.maintenance,
            dash: const [3, 4],
          ),
          const SizedBox(width: 16),
          _LegendItem(
            label: intl.health.legendDown,
            color: c.danger,
            dash: const [3, 4],
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: c.outlineCard,
          ),
          AppIconButton(
            icon: const SvgAsset('<path d="M5 12h14"/>'),
            tooltip: intl.map.zoomOut,
            size: 32,
            iconSize: 16,
            onPressed: _scale > 0.41 ? () => _zoom(1 / 1.2) : null,
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${(_scale * 100).round()}%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.label),
            ),
          ),
          AppIconButton(
            icon: app.assets.icons.actions.add,
            tooltip: intl.map.zoomIn,
            size: 32,
            iconSize: 16,
            onPressed: _scale < 1.99 ? () => _zoom(1.2) : null,
          ),
          const SizedBox(width: 10),
          AppButton(
            label: intl.map.fit,
            kind: AppButtonKind.outlined,
            height: 36,
            fontSize: 13,
            onPressed: () => _fit(layout),
          ),
          const SizedBox(width: 16),
          AppButton(
            label: intl.routes.createRoute,
            icon: app.assets.icons.actions.add,
            height: 40,
            onPressed: RoutesFormScreen.navigator.create,
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas(BuildContext context, _Layout layout) {
    final c = app.colors;
    final intl = context.intl;
    final maintenance = app.di.find<MaintenanceCubit>();
    final gatewayOn = maintenance.gatewayOn;
    final routes = _routes.routes;
    final selected = GatewayMapScreen.selected.value;
    final selectedRoute = routes.any((r) => r.id == selected) ? selected : null;
    final panelId = selected == GatewayMapScreen.gatewayId
        ? GatewayMapScreen.gatewayId
        : selectedRoute;
    final branches = [
      for (var i = 0; i < routes.length; i++)
        _Branch(
          from: Offset(layout.startX(i), layout.gwBottom),
          to: Offset(layout.cardCenter(i), _Layout.cardTop),
          status: RouteStatus.of(routes[i], gatewayOn: gatewayOn),
          dimmed: selectedRoute != null && routes[i].id != selectedRoute,
        ),
      if (routes.isEmpty && _routes.loaded)
        _Branch(
          from: Offset(layout.cx, layout.gwBottom),
          to: Offset(layout.cx, _Layout.cardTop),
          status: null,
          dimmed: false,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
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
                    child: SizedBox(
                      width: layout.width,
                      height: layout.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _BranchesPainter(
                                branches: branches,
                                entry: Offset(layout.cx, _Layout.urlH),
                                entryEnd: Offset(layout.cx, _Layout.gwTop - 4),
                                flow: _flow,
                                arrowColor: c.textTertiary,
                              ),
                            ),
                          ),
                          Positioned(
                            left: layout.cx - _Layout.urlW / 2,
                            top: 0,
                            width: _Layout.urlW,
                            height: _Layout.urlH,
                            child: _UrlNode(url: Environment.gatewayUrl),
                          ),
                          Positioned(
                            left: layout.cx - _Layout.gwW / 2,
                            top: _Layout.gwTop,
                            width: _Layout.gwW,
                            height: _Layout.gwH,
                            child: _GatewayNode(
                              routes: routes,
                              maintenance: maintenance.gateway,
                              selected: panelId == GatewayMapScreen.gatewayId,
                              onTap: () => _select(GatewayMapScreen.gatewayId),
                            ),
                          ),
                          for (var i = 0; i < routes.length; i++) ...[
                            Positioned(
                              left:
                                  (layout.startX(i) + layout.cardCenter(i)) / 2,
                              top: layout.labelY,
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, -0.5),
                                child: Opacity(
                                  opacity: branches[i].dimmed ? 0.35 : 1,
                                  child: _PathLabel(
                                    path: routes[i].path,
                                    status: branches[i].status,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: layout.cardLeft(i),
                              top: _Layout.cardTop,
                              width: _Layout.cardW,
                              height: _Layout.cardH,
                              child: Opacity(
                                opacity: branches[i].dimmed ? 0.55 : 1,
                                child: _RouteNode(
                                  route: routes[i],
                                  gatewayOn: gatewayOn,
                                  selected: routes[i].id == selectedRoute,
                                  onTap: () => _select(routes[i].id),
                                ),
                              ),
                            ),
                          ],
                          if (routes.isEmpty && _routes.loaded)
                            Positioned(
                              left: layout.cx - _Layout.cardW / 2,
                              top: _Layout.cardTop,
                              width: _Layout.cardW,
                              height: _Layout.cardH,
                              child: const _AddRouteNode(),
                            ),
                        ],
                      ),
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
            if (panelId != null)
              Positioned(
                top: 12,
                right: 12,
                bottom: 12,
                width: _panelW,
                child: RoutePanel(
                  key: ValueKey(panelId),
                  routeId: panelId == GatewayMapScreen.gatewayId
                      ? null
                      : panelId,
                  redirectLabel: intl.panel.openInRoutes,
                  onClose: () => GatewayMapScreen.selected.value = null,
                  onRedirect: (route) {
                    _routes.query.value = route.name;
                    app.navigator.go(RoutesScreen.navigator.name);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Branch {
  static const Color redirectColor = Color(0xff8b80c0);

  final Offset from;
  final Offset to;

  ///null = the dotted branch to the "Add route" card
  final RouteStatus? status;
  final bool dimmed;

  const _Branch({
    required this.from,
    required this.to,
    required this.status,
    required this.dimmed,
  });

  bool get maintenance => status?.inMaintenance ?? false;

  ///forwarding with nothing wrong: the moving branch (as in the canvas, DOWN stands still)
  bool get flowing => status == RouteStatus.none || status == RouteStatus.live;
}

class _BranchesPainter extends CustomPainter {
  final List<_Branch> branches;
  final Offset entry;
  final Offset entryEnd;
  final Animation<double> flow;
  final Color arrowColor;

  _BranchesPainter({
    required this.branches,
    required this.entry,
    required this.entryEnd,
    required this.flow,
    required this.arrowColor,
  }) : super(repaint: flow);

  @override
  void paint(Canvas canvas, Size size) {
    final maint = app.colors.maintenance;
    //the url into the gateway: solid, with its arrow
    final entryPaint = Paint()
      ..color = arrowColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(entry, entryEnd, entryPaint);
    _arrow(canvas, entryEnd, entryPaint);

    for (final b in branches) {
      final midY = (b.from.dy + b.to.dy) / 2;
      final end = b.to - const Offset(0, 6);
      final path = Path()
        ..moveTo(b.from.dx, b.from.dy)
        ..cubicTo(b.from.dx, midY, b.to.dx, midY, end.dx, end.dy);
      final color = b.status == null
          ? app.colors.textTertiary
          : b.maintenance
          ? maint
          : b.status == RouteStatus.down
          ? app.colors.danger
          : _Branch.redirectColor;
      final paint = Paint()
        ..color = color.withValues(alpha: b.dimmed ? 0.3 : 1)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      //redirects flow; maintenance (nothing goes through), DOWN and the empty branch stand still
      final dash = b.flowing ? [6.0, 5.0] : [3.0, 4.0];
      _dashed(canvas, path, paint, dash, b.flowing ? flow.value : 0);
      _arrow(canvas, end, paint);
    }
  }

  void _dashed(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> dash,
    double phase,
  ) {
    final period = dash[0] + dash[1];
    for (final metric in path.computeMetrics()) {
      var d = -period + (phase * period);
      while (d < metric.length) {
        final start = max(0.0, d);
        final stop = min(metric.length, d + dash[0]);
        if (stop > start) {
          canvas.drawPath(metric.extractPath(start, stop), paint);
        }
        d += period;
      }
    }
  }

  void _arrow(Canvas canvas, Offset tip, Paint paint) {
    final p = Path()
      ..moveTo(tip.dx - 5, tip.dy - 6)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 5, tip.dy - 6);
    canvas.drawPath(p, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _BranchesPainter old) =>
      old.branches != branches;
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final List<double> dash;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.dash,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 2),
          painter: _LinePainter(color, dash),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: app.colors.label)),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final List<double> dash;

  _LinePainter(this.color, this.dash);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(min(x + dash[0], size.width), size.height / 2),
        paint,
      );
      x += dash[0] + dash[1];
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => false;
}

class _UrlNode extends StatelessWidget {
  final String url;

  const _UrlNode({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SvgAsset(
            '<circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>',
          ).build(size: 15, color: c.textTertiary),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(size: 13, color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

///a node of the map: clickable card with a hover shadow and the selection ring
class _Node extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final bool dashed;
  final Color background;
  final Color border;
  final String semanticLabel;

  const _Node({
    required this.child,
    required this.onTap,
    required this.selected,
    required this.background,
    required this.border,
    required this.semanticLabel,
    this.dashed = false,
  });

  @override
  State<_Node> createState() => _NodeState();
}

class _NodeState extends State<_Node> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final border = widget.selected ? c.lilac : widget.border;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: motion(context, const Duration(milliseconds: 150)),
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(16),
              border: widget.dashed && !widget.selected
                  ? null
                  : Border.all(color: border, width: widget.selected ? 2 : 1),
              boxShadow: [
                if (_hovered)
                  const BoxShadow(
                    color: Color(0x73000000),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: widget.dashed && !widget.selected
                  ? DashedBorder(color: border, radius: 16, width: 1.2)
                  : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GatewayNode extends StatelessWidget {
  final List<RouteModel> routes;
  final MaintenanceModel? maintenance;
  final bool selected;
  final VoidCallback onTap;

  const _GatewayNode({
    required this.routes,
    required this.maintenance,
    required this.selected,
    required this.onTap,
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
    return _Node(
      onTap: onTap,
      selected: selected,
      dashed: on,
      background: on ? const Color(0xff221b1f) : c.surface,
      border: on ? c.maintenance : c.outline,
      semanticLabel: 'api-gateway',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
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
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ] else
                    Text(
                      [
                        routesText,
                        if (inMaint > 0)
                          intl.maintenance.inCount(count: inMaint),
                      ].join(' · '),
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathLabel extends StatelessWidget {
  final String path;
  final RouteStatus? status;

  const _PathLabel({required this.path, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final maint =
        status == RouteStatus.maintenance || status == RouteStatus.paused;
    final color = maint ? c.maintenance : c.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.gridBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: maint ? c.maintenance.withValues(alpha: 0.7) : c.outline,
        ),
      ),
      child: Text(path, style: monoStyle(size: 12, color: color)),
    );
  }
}

class _RouteNode extends StatelessWidget {
  final RouteModel route;
  final bool gatewayOn;
  final bool selected;
  final VoidCallback onTap;

  const _RouteNode({
    required this.route,
    required this.gatewayOn,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final status = RouteStatus.of(route, gatewayOn: gatewayOn);
    final ownOn = status == RouteStatus.maintenance;
    final maintenance = route.maintenance;
    final health = route.healthCheck;
    final host = Uri.tryParse(route.uri)?.host;
    return _Node(
      onTap: onTap,
      selected: selected,
      dashed: ownOn,
      background: ownOn ? const Color(0xff221b1f) : c.card,
      border: ownOn
          ? c.maintenance
          : status == RouteStatus.down
          ? c.danger.withValues(alpha: 0.6)
          : c.outlineCard,
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
            if (maintenance == null && health == null)
              Text(
                intl.maintenance.redirectOnly,
                style: TextStyle(fontSize: 12, color: c.textTertiary),
              )
            else
              Row(
                children: [
                  if (health != null) ...[
                    _Chip(
                      icon: app.assets.icons.general.activity,
                      color: health.down ? c.dangerText : null,
                      label: health.enabled
                          ? intervalText(health.intervalSeconds)
                                .replaceAll(' ', '')
                          : intl.maintenance.chipOff,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (maintenance != null)
                    _Chip(
                      icon: app.assets.icons.general.wrench,
                      color: maintenance.enabled ? c.maintenance : null,
                      label: maintenance.enabled
                          ? intl.maintenance.chipOn
                          : intl.maintenance.chipOff,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

///an add-on of the node; [color] null = plain (off, or nothing to flag)
class _Chip extends StatelessWidget {
  final SvgAsset icon;
  final Color? color;
  final String label;

  const _Chip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final accent = this.color;
    final color = accent ?? c.label;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: accent?.withValues(alpha: 0.10) ?? Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: accent?.withValues(alpha: 0.6) ?? c.outlineCard,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon.build(size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _AddRouteNode extends StatelessWidget {
  const _AddRouteNode();

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return _Node(
      onTap: RoutesFormScreen.navigator.create,
      selected: false,
      dashed: true,
      background: Colors.transparent,
      border: c.outline,
      semanticLabel: intl.map.addRoute,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                app.assets.icons.actions.add.build(size: 16, color: c.text),
                const SizedBox(width: 8),
                Text(
                  intl.map.addRoute,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              intl.map.noRoutesYet,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

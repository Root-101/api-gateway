import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class LogDetailsScreen extends StatefulWidget {
  static void open(HttpLogModel log) {
    app.dialog.open(dialog: LogDetailsScreen(log: log));
  }

  final HttpLogModel log;

  const LogDetailsScreen({required this.log, super.key});

  @override
  State<LogDetailsScreen> createState() => _LogDetailsScreenState();
}

class _LogDetailsScreenState extends State<LogDetailsScreen> {
  final FocusNode _close = FocusNode();

  @override
  void dispose() {
    _close.dispose();
    super.dispose();
  }

  void _openRoute(String name) {
    final routes = app.di.find<RoutesCubit>();
    routes.query.value = name;
    Navigator.of(context).pop();
    app.navigator.go(RoutesScreen.navigator.name);
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final log = widget.log;
    final route = log.route;
    //"Admin" is logged as a route but can't be opened: only routes that exist in the list can
    final exists =
        route != null &&
        app.di.find<RoutesCubit>().routes.any((r) => r.id == route.routeId);
    return DialogTemplate(
      title: intl.logDetails.title,
      closeFocusNode: _close,
      footer: exists
          ? Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: intl.logDetails.openRoute(name: route.routeName),
                height: 44,
                onPressed: () => _openRoute(route.routeName),
              ),
            )
          : null,
      body: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.outlineCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.raised,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.httpMethod,
                          style: monoStyle(
                            size: 12,
                            weight: FontWeight.w500,
                            color: c.methodColor(log.httpMethod),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(log.responseCode, height: 26),
                      const Spacer(),
                      Text(
                        intl.logs.durationMs(ms: log.requestDuration),
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    log.path,
                    style: monoStyle(size: 15, height: 22 / 15, color: c.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _section(intl.logDetails.request, [
              _Item(
                intl.logDetails.timestamp,
                app.dateFormatter.logsTime.format(log.requestedAtLocal),
              ),
              _Item(intl.logDetails.sourceIp, log.sourceIp),
              _Item(intl.logDetails.userAgent, log.userAgent),
            ]),
            const SizedBox(height: 18),
            _section(
              intl.logDetails.route,
              route == null
                  ? [
                      _Item(
                        intl.logDetails.routeName,
                        intl.logFilters.filterNoRouteName,
                        mono: true,
                        muted: true,
                      ),
                    ]
                  : [
                      _Item(
                        intl.logDetails.routeName,
                        route.routeName,
                        mono: true,
                      ),
                      _Item(
                        intl.logDetails.routePath,
                        route.routePath,
                        mono: true,
                      ),
                      _Item(intl.logDetails.routeId, route.routeId, mono: true),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<_Item> items) {
    final c = app.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CaptionText(title, color: c.textSecondary, size: 12),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: c.field,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: i == items.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: c.outlineSoft)),
                  ),
                  child: items[i],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool muted;

  const _Item(this.label, this.value, {this.mono = false, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final color = muted ? c.textTertiary : c.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              height: 20 / 13,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: mono
                ? monoStyle(height: 20 / 13, color: color)
                : TextStyle(fontSize: 13, height: 20 / 13, color: color),
          ),
        ),
      ],
    );
  }
}

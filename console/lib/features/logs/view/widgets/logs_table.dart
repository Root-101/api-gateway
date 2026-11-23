import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///the requests table: column titles, then skeleton rows while it boots or a row per log.
///Under 860 px it scrolls sideways
class LogsTable extends StatelessWidget {
  static const _skeletonWidths = [
    240.0,
    180.0,
    280.0,
    210.0,
    260.0,
    150.0,
    220.0,
    190.0,
  ];

  final bool booting;
  final List<HttpLogModel> items;

  ///shown under the titles instead of the rows (no request matches)
  final Widget? empty;

  const LogsTable({
    required this.booting,
    required this.items,
    this.empty,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    Widget title(String text) =>
        CaptionText(text, size: 11, color: c.textSecondary);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: max(860, constraints.maxWidth),
          //the titles stay, the rows scroll under them
          child: Column(
            children: [
              Container(
                height: 40,
                color: c.surface,
                child: _LogCells(
                  title(intl.logs.columnTimestamp),
                  title(intl.logs.columnMethod),
                  title(intl.logs.columnPath),
                  title(intl.logs.columnRoute),
                  title(intl.logs.columnHttpStatus),
                  title(intl.logs.columnRequestDuration),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    if (booting)
                      for (final width in _skeletonWidths)
                        _LogRowFrame(
                          child: _LogCells(
                            const AppSkeleton(width: 130),
                            const AppSkeleton(width: 40),
                            AppSkeleton(width: width),
                            const AppSkeleton(width: 90),
                            const AppSkeleton(
                              width: 52,
                              height: 22,
                              radius: 11,
                            ),
                            const AppSkeleton(width: 44),
                          ),
                        )
                    else if (empty case final empty?)
                      //the visible width, not the 860 of the columns
                      Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: empty,
                        ),
                      )
                    else
                      for (final log in items) LogRow(log: log),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///one request: a click opens its details
class LogRow extends StatelessWidget {
  final HttpLogModel log;

  const LogRow({required this.log, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    const tabular = [FontFeature.tabularFigures()];
    return _LogRowFrame(
      child: Semantics(
        button: true,
        label: '${log.httpMethod} ${log.path}',
        child: InkWell(
          hoverColor: c.surface,
          onTap: () => LogDetailsScreen.open(log),
          child: _LogCells(
            Text(
              app.dateFormatter.logsTime.format(log.requestedAtLocal),
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                fontFeatures: tabular,
              ),
            ),
            Text(
              log.httpMethod,
              style: monoStyle(
                size: 12,
                weight: FontWeight.w500,
                letterSpacing: 0.4,
                color: c.methodColor(log.httpMethod),
              ),
            ),
            Text(
              log.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(color: c.text),
            ),
            Text(
              log.route?.routeName ?? intl.logFilters.filterNoRouteName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: log.route == null ? c.textTertiary : c.text,
              ),
            ),
            StatusPill(log.responseCode),
            Text(
              intl.logs.durationMs(ms: log.requestDuration),
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                fontFeatures: tabular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

///a 48 px row with the line above it
class _LogRowFrame extends StatelessWidget {
  final Widget child;

  const _LogRowFrame({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: app.colors.outlineSoft)),
    ),
    child: child,
  );
}

///the six columns: fixed widths, the path takes the rest, the duration aligned right
class _LogCells extends StatelessWidget {
  final Widget timestamp;
  final Widget method;
  final Widget path;
  final Widget route;
  final Widget status;
  final Widget duration;

  const _LogCells(
    this.timestamp,
    this.method,
    this.path,
    this.route,
    this.status,
    this.duration,
  );

  @override
  Widget build(BuildContext context) {
    Widget cell(
      Widget child, {
      double? width,
      Alignment align = Alignment.centerLeft,
    }) {
      final padded = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Align(alignment: align, child: child),
      );
      return width == null
          ? Expanded(child: padded)
          : SizedBox(width: width, child: padded);
    }

    return Row(
      children: [
        cell(timestamp, width: 200),
        cell(method, width: 100),
        cell(path),
        cell(route, width: 190),
        cell(status, width: 110),
        cell(duration, width: 110, align: Alignment.centerRight),
      ],
    );
  }
}

///no request matches the search or the filters
class LogsEmpty extends StatelessWidget {
  final VoidCallback onClearAll;

  const LogsEmpty({required this.onClearAll, super.key});

  @override
  Widget build(BuildContext context) {
    final intl = context.intl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: app.colors.outlineSoft)),
      ),
      child: EmptyState(
        icon: app.assets.icons.general.inbox,
        title: intl.logs.noMatches,
        action: AppButton(
          label: intl.logs.clearAll,
          kind: AppButtonKind.outlined,
          onPressed: onClearAll,
        ),
      ),
    );
  }
}

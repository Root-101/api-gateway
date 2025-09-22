import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class LogDetailsScreen extends StatelessWidget {
  static void open(HttpLogModel log) {
    DialogTemplate.open(
      title: app.intl.logDetails,
      child: LogDetailsScreen(log: log),
    );
  }

  final HttpLogModel log;

  const LogDetailsScreen({required this.log, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(app.dimensions.padding.l),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    log.route?.routeName ?? app.intl.filterNoRouteName,
                    style: app.textTheme.headlineMedium?.copyWith(
                      color: log.route != null
                          ? app.colors.neutral.white
                          : app.colors.neutral.grey4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    log.path,
                    style: app.textTheme.bodyMedium?.copyWith(
                      color: app.colors.neutral.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  app.dimensions.padding.xxl.gap(),
                ],
              ),

              section(
                children: [
                  buildItem(
                    key: app.intl.logsDetailsTimestamp,
                    value: app.dateFormatter.logsTime.format(
                      log.requestedAtLocal,
                    ),
                  ),
                  divider(),

                  app.dimensions.padding.sm.gap(),
                  buildItem(
                    key: app.intl.logsDetailsSourceIp,
                    value: log.sourceIp,
                  ),
                  divider(),

                  app.dimensions.padding.sm.gap(),
                  buildItem(
                    key: app.intl.logsDetailsHttpMethod,
                    value: log.httpMethod,
                  ),
                  divider(),

                  app.dimensions.padding.sm.gap(),
                  buildItem(
                    key: app.intl.logsDetailsHttpStatus,
                    value: log.responseCode.toString(),
                  ),
                  divider(),

                  app.dimensions.padding.sm.gap(),
                  buildItem(
                    key: app.intl.logsDetailsRequestDuration,
                    value: '${log.requestDuration} ms',
                  ),
                  divider(),

                  app.dimensions.padding.sm.gap(),
                  buildItem(
                    key: app.intl.logsDetailsUserAgent,
                    value: log.userAgent,
                  ),
                ],
              ),

              app.dimensions.padding.xxl.gap(),

              section(
                label: app.intl.logsDetailsRoute,
                children: [
                  buildItem(
                    key: app.intl.logsDetailsRouteName,
                    value: log.route?.routeName ?? noRoute.routeName,
                  ),
                  divider(),

                  app.dimensions.padding.sm.gap(),
                  buildItem(
                    key: app.intl.logsDetailsRoutePath,
                    value: log.route?.routePath ?? noRoute.routePath,
                  ),
                  divider(),

                  app.dimensions.padding.sm.gap(),
                  buildItem(
                    key: app.intl.logsDetailsRouteId,
                    value: log.route?.routeId ?? noRoute.routeId,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget section({required List<Widget> children, String? label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: EdgeInsets.only(left: app.dimensions.padding.s),
            child: Text(
              label,
              style: app.textTheme.titleSmall?.copyWith(
                color: app.colors.neutral.grey2,
              ),
            ),
          ),
          app.dimensions.padding.s.gap(),
        ],
        Container(
          decoration: BoxDecoration(
            color: app.colors.primary.background1.brighten(0.015),
            borderRadius: app.dimensions.border.borderRadius.m,
          ),
          child: Padding(
            padding: EdgeInsets.all(app.dimensions.padding.l),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [...children],
            ),
          ),
        ),
      ],
    );
  }

  Widget divider() {
    return Divider(color: app.colors.neutral.grey4);
  }

  Widget buildItem({required String key, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            key,
            style: app.textTheme.bodyMedium?.copyWith(
              color: app.colors.neutral.grey3,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SelectionArea(
              child: Text(
                value,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.white,
                ),
                softWrap: true,
                maxLines: null,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

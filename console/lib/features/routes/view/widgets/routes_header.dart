import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/routes_form_screen.dart';
import 'package:flutter/material.dart';

///Routes' title with its counts (routes, in maintenance, down), and backup, restore and create
class RoutesHeader extends StatelessWidget {
  final List<RouteModel> routes;
  final VoidCallback onBackup;

  const RoutesHeader({required this.routes, required this.onBackup, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final count = routes.length;
    final inMaintenance = routes.where((r) => r.inMaintenance).length;
    final down = routes.where((r) => r.healthCheck?.down ?? false).length;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              intl.routes.routes,
              style: TextStyle(
                fontSize: 26,
                height: 32 / 26,
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                count == 1
                    ? intl.routes.oneRoute
                    : intl.routes.manyRoutes(count: count),
                if (inMaintenance > 0)
                  intl.maintenance.inCount(count: inMaintenance),
                if (down > 0) intl.health.downCount(count: down),
              ].join(' · '),
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: intl.routes.backup,
              icon: app.assets.icons.actions.download,
              kind: AppButtonKind.outlined,
              onPressed: onBackup,
            ),
            const SizedBox(width: 8),
            AppButton(
              label: intl.routes.restore,
              icon: app.assets.icons.actions.upload,
              kind: AppButtonKind.outlined,
              onPressed: RoutesRestoreDialog.show,
            ),
            Container(
              width: 1,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: c.outlineField,
            ),
            AppButton(
              label: intl.routes.createRoute,
              icon: app.assets.icons.actions.add,
              onPressed: RoutesFormScreen.navigator.create,
            ),
          ],
        ),
      ],
    );
  }
}

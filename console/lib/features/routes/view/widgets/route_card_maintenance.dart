import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///what callers of a route in maintenance get, under its urls
class RouteCardMaintenance extends StatelessWidget {
  final MaintenanceModel maintenance;

  const RouteCardMaintenance(this.maintenance, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final retry = maintenance.retryAfter?.toLocal();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.maintenance.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.maintenance.withValues(alpha: 0.35)),
      ),
      child: Column(
        //stretched so the return time goes to the right edge
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  app.assets.icons.general.wrench.build(
                    size: 13,
                    color: c.maintenance,
                  ),
                  const SizedBox(width: 6),
                  CaptionText(intl.maintenance.cardTitle, color: c.maintenance),
                ],
              ),
              Text(
                retry == null
                    ? intl.maintenance.cardNoTime
                    : intl.maintenance.cardBack(
                        date: app.dateFormatter.dayTime.format(retry),
                      ),
                style: TextStyle(fontSize: 12, height: 16 / 12, color: c.label),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            maintenance.shownMessage(intl.maintenance.defaultMessage),
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: maintenance.hasOwnMessage ? c.text : c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

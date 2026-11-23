import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class MapPathLabel extends StatelessWidget {
  final String path;
  final RouteStatus? status;

  const MapPathLabel({required this.path, required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final maint =
        status == RouteStatus.maintenance || status == RouteStatus.paused;
    final down = status == RouteStatus.down;
    final color = maint
        ? c.maintenance
        : down
        ? c.dangerText
        : c.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.gridBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: maint
              ? c.maintenance.withValues(alpha: 0.7)
              : down
              ? c.danger
              : c.outline,
        ),
      ),
      child: Text(path, style: monoStyle(size: 12, color: color)),
    );
  }
}

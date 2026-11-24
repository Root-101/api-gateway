import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///the map's top bar: title, legend, zoom, fit and "Create route"
class MapHeader extends StatelessWidget {
  final double scale;
  final ValueChanged<double> onZoom;
  final VoidCallback onFit;

  const MapHeader({
    required this.scale,
    required this.onZoom,
    required this.onFit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
          MapLegendItem(
            label: intl.map.legendRedirect,
            color: app.colors.redirect,
            dash: const [6, 5],
          ),
          const SizedBox(width: 16),
          MapLegendItem(
            label: intl.map.legendMaintenance,
            color: c.maintenance,
            dash: const [3, 4],
          ),
          const SizedBox(width: 16),
          MapLegendItem(
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
            icon: app.assets.icons.actions.minus,
            tooltip: intl.map.zoomOut,
            size: 32,
            iconSize: 16,
            onPressed: scale > 0.41 ? () => onZoom(1 / 1.2) : null,
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${(scale * 100).round()}%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.label),
            ),
          ),
          AppIconButton(
            icon: app.assets.icons.actions.add,
            tooltip: intl.map.zoomIn,
            size: 32,
            iconSize: 16,
            onPressed: scale < 1.99 ? () => onZoom(1.2) : null,
          ),
          const SizedBox(width: 10),
          AppButton(
            label: intl.map.fit,
            kind: AppButtonKind.outlined,
            height: 36,
            fontSize: 13,
            onPressed: onFit,
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
}

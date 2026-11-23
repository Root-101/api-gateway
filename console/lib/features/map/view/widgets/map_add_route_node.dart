import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/routes_form_screen.dart';
import 'package:material_ui/material_ui.dart';

class MapAddRouteNode extends StatelessWidget {
  const MapAddRouteNode({super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return MapNode(
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

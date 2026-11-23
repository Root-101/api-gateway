import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class MapUrlNode extends StatelessWidget {
  final String url;

  const MapUrlNode({required this.url, super.key});

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
          app.assets.icons.general.web.build(size: 15, color: c.textTertiary),
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

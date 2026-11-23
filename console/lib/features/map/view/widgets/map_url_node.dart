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

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///"FROM" / "TO" caption with its url, shared by the card, the preview and the delete dialog
class RouteUrlBlock extends StatelessWidget {
  final String caption;
  final String url;
  final bool accent;
  final double fontSize;
  final Color? urlColor;

  const RouteUrlBlock({
    required this.caption,
    required this.url,
    this.accent = false,
    this.fontSize = 13,
    this.urlColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CaptionText(caption, color: accent ? c.lilac : c.textTertiary),
        const SizedBox(height: 2),
        Text(
          url,
          style: monoStyle(
            size: fontSize,
            color: urlColor ?? c.text,
            height: 20 / 13,
          ),
        ),
      ],
    );
  }
}

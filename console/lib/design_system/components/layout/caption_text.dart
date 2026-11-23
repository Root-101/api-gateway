import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///10-12 px uppercase caption used over urls and table columns
class CaptionText extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;

  const CaptionText(this.text, {this.color, this.size = 10, super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      height: 1.4,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: color ?? app.colors.textTertiary,
    ),
  );
}

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FieldLabel(this.text, {this.required = false, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: c.lilac),
            ),
        ],
      ),
      style: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: c.label,
      ),
    );
  }
}

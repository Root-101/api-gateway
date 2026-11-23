import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class AppTagline extends StatelessWidget {
  final double size;
  final double letterSpacing;

  const AppTagline({required this.size, this.letterSpacing = 0, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Text.rich(
      TextSpan(
        text: '${context.intl.app.taglineStart} ',
        children: [
          TextSpan(
            text: context.intl.app.taglineEnd,
            style: TextStyle(color: c.lilac),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: c.lilacText,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final Color? color;

  const AppLogo({required this.width, this.color, super.key});

  @override
  Widget build(BuildContext context) => app.assets.icons.gateway.build(
    size: width,
    height: width * 23 / 24,
    color: color ?? app.colors.lilac,
  );
}

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///the product name: always lowercase, DM Mono, with "api" in lilac
class AppWordmark extends StatelessWidget {
  final double size;
  final double letterSpacing;

  const AppWordmark({
    required this.size,
    required this.letterSpacing,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: 'api',
      style: TextStyle(color: app.colors.lilac),
      children: [
        TextSpan(
          text: '-gateway',
          style: TextStyle(color: app.colors.white),
        ),
      ],
    ),
    maxLines: 1,
    softWrap: false,
    style: monoStyle(
      size: size,
      weight: FontWeight.w500,
      height: 1,
      letterSpacing: letterSpacing,
    ),
  );
}

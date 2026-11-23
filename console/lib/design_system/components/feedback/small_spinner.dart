import 'package:material_ui/material_ui.dart';

///spinner sized for buttons and banners
class SmallSpinner extends StatelessWidget {
  final Color color;
  final double size;

  const SmallSpinner({required this.color, this.size = 14, super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}

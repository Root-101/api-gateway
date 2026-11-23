import 'dart:ui';
import 'dart:math';
import 'package:material_ui/material_ui.dart';

///a rounded border drawn in dashes (`foregroundPainter` of a CustomPaint):
///the map's nodes in maintenance and "Add route", the panel's "Add to this route"
class DashedBorder extends CustomPainter {
  final Color color;
  final double radius;
  final double width;

  ///length of each dash and of the space after it
  final double dash;
  final double gap;

  DashedBorder({
    required this.color,
    required this.radius,
    this.width = 1.2,
    this.dash = 4,
    this.gap = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(width / 2),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    for (final PathMetric metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, min(d + dash, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorder old) =>
      old.color != color ||
      old.radius != radius ||
      old.width != width ||
      old.dash != dash ||
      old.gap != gap;
}

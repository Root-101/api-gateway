import 'package:api_gateway_front/main.dart';
import 'package:flutter/material.dart';

class GridDotPainter extends CustomPainter {
  final double? spacing;
  final double? radius;
  final Color? color;

  GridDotPainter({this.spacing, this.radius, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double safeSpacing = spacing ?? 30;
    final double safeRadius = radius ?? 0.75;
    final Color safeColor =
        color ?? app.colors.neutral.grey5.withValues(alpha: 0.6);
    final paint =
        Paint()
          ..color = safeColor
          ..style = PaintingStyle.fill;

    for (double y = safeSpacing / 5; y < size.height; y += safeSpacing) {
      for (double x = safeSpacing / 5; x < size.width; x += safeSpacing) {
        canvas.drawCircle(Offset(x, y), safeRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

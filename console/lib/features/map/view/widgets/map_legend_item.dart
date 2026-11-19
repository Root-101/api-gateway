import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class MapLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final List<double> dash;

  const MapLegendItem({
    required this.label,
    required this.color,
    required this.dash,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 2),
          painter: MapLegendLinePainter(color, dash),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: app.colors.label)),
      ],
    );
  }
}

class MapLegendLinePainter extends CustomPainter {
  final Color color;
  final List<double> dash;

  MapLegendLinePainter(this.color, this.dash);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(min(x + dash[0], size.width), size.height / 2),
        paint,
      );
      x += dash[0] + dash[1];
    }
  }

  @override
  bool shouldRepaint(covariant MapLegendLinePainter old) => false;
}

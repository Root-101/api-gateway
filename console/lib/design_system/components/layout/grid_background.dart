import 'package:console/app_exporter.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

///page background: flat night color with a 48 px line grid.
///With [view] the grid pans and zooms with it (the gateway map's canvas)
class GridBackground extends StatelessWidget {
  final Widget? child;
  final ValueListenable<Matrix4>? view;

  const GridBackground({this.child, this.view, super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GridPainter(app.colors.gridBg, app.colors.gridLine, view),
    child: child,
  );
}

class _GridPainter extends CustomPainter {
  final Color background;
  final Color line;
  final ValueListenable<Matrix4>? view;

  _GridPainter(this.background, this.line, this.view) : super(repaint: view);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()..color = line;
    final m = view?.value.storage;
    //x scale and translation of the view; identity without one
    final scale = m?[0] ?? 1;
    final step = 48 * scale;
    double first(double t) => (t + 47 * scale) % step;
    for (double x = first(m?[12] ?? 0); x < size.width; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);
    }
    for (double y = first(m?[13] ?? 0); y < size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.view != view;
}

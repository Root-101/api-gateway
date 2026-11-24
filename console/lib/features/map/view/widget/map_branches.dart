import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class MapBranch {
  final Offset from;
  final Offset to;

  ///null = the dotted branch to the "Add route" card
  final RouteStatus? status;
  final bool dimmed;

  const MapBranch({
    required this.from,
    required this.to,
    required this.status,
    required this.dimmed,
  });

  bool get maintenance => status?.inMaintenance ?? false;

  ///forwarding with nothing wrong: the moving branch (as in the canvas, DOWN stands still)
  bool get flowing => status == RouteStatus.none || status == RouteStatus.live;
}

class MapBranchesPainter extends CustomPainter {
  final List<MapBranch> branches;
  final Offset entry;
  final Offset entryEnd;
  final Animation<double> flow;
  final Color arrowColor;

  MapBranchesPainter({
    required this.branches,
    required this.entry,
    required this.entryEnd,
    required this.flow,
    required this.arrowColor,
  }) : super(repaint: flow);

  @override
  void paint(Canvas canvas, Size size) {
    final maint = app.colors.maintenance;
    //the url into the gateway: solid, with its arrow
    final entryPaint = Paint()
      ..color = arrowColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(entry, entryEnd, entryPaint);
    _arrow(canvas, entryEnd, entryPaint);

    for (final b in branches) {
      final midY = (b.from.dy + b.to.dy) / 2;
      final end = b.to - const Offset(0, 6);
      final path = Path()
        ..moveTo(b.from.dx, b.from.dy)
        ..cubicTo(b.from.dx, midY, b.to.dx, midY, end.dx, end.dy);
      final color = b.status == null
          ? app.colors.textTertiary
          : b.maintenance
          ? maint
          : b.status == RouteStatus.down
          ? app.colors.danger
          : app.colors.redirect;
      final paint = Paint()
        ..color = color.withValues(alpha: b.dimmed ? 0.3 : 1)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      //redirects flow; maintenance (nothing goes through), DOWN and the empty branch stand still
      final dash = b.flowing ? [6.0, 5.0] : [3.0, 4.0];
      _dashed(canvas, path, paint, dash, b.flowing ? flow.value : 0);
      _arrow(canvas, end, paint);
    }
  }

  void _dashed(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> dash,
    double phase,
  ) {
    final period = dash[0] + dash[1];
    for (final metric in path.computeMetrics()) {
      var d = -period + (phase * period);
      while (d < metric.length) {
        final start = max(0.0, d);
        final stop = min(metric.length, d + dash[0]);
        if (stop > start) {
          canvas.drawPath(metric.extractPath(start, stop), paint);
        }
        d += period;
      }
    }
  }

  void _arrow(Canvas canvas, Offset tip, Paint paint) {
    final p = Path()
      ..moveTo(tip.dx - 5, tip.dy - 6)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 5, tip.dy - 6);
    canvas.drawPath(p, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant MapBranchesPainter old) =>
      old.branches != branches;
}

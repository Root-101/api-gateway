import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class RouteBadge extends StatelessWidget {
  final SvgAsset icon;
  final String label;
  final Color color;
  final bool dashed;
  final VoidCallback onPressed;

  const RouteBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.dashed = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final accent = color != c.label;
    final badge = Material(
      color: accent ? color.withValues(alpha: 0.10) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: dashed
            ? BorderSide.none
            : BorderSide(
                color: accent ? color.withValues(alpha: 0.5) : c.outlineCard,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon.build(size: 13, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
    //dashed 1 px border, as in the canvas
    return dashed
        ? CustomPaint(
            foregroundPainter: DashedBorder(
              color: c.outline,
              radius: 8,
              width: 1,
            ),
            child: badge,
          )
        : badge;
  }
}

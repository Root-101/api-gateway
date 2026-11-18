import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///an add-on of the node; [color] null = plain (off, or nothing to flag)
class MapChip extends StatelessWidget {
  final SvgAsset icon;
  final Color? color;
  final String label;

  const MapChip({
    required this.icon,
    required this.color,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final accent = this.color;
    final color = accent ?? c.label;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: accent?.withValues(alpha: 0.10) ?? Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: accent?.withValues(alpha: 0.6) ?? c.outlineCard,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon.build(size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

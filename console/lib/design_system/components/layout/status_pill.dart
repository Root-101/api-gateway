import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class StatusPill extends StatelessWidget {
  final int status;
  final double height;

  const StatusPill(this.status, {this.height = 24, super.key});

  @override
  Widget build(BuildContext context) {
    final tone = app.colors.statusTone(status);
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tone.fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///empty state: icon tile, title and whatever comes below
class EmptyState extends StatelessWidget {
  final SvgAsset icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.raised,
            borderRadius: BorderRadius.circular(18),
          ),
          child: icon.build(size: 26, color: c.lilac),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: c.text,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    );
  }
}

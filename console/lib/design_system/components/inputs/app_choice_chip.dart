import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///selectable filter chip; [pressed] is announced to screen readers
class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final bool mono;
  final Color? dot;
  final Alignment align;

  const AppChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 36,
    this.mono = false,
    this.dot,
    this.align = Alignment.center,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final color = selected ? c.onSelected : c.label;
    final style = mono
        ? monoStyle(color: color, weight: FontWeight.w500)
        : TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.selected : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? c.selected : c.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: align,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dot != null)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    )
                  else if (selected)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: app.assets.icons.general.check.build(
                        size: 14,
                        color: color,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      label,
                      style: style,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

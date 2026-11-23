import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class AppIconButton extends StatelessWidget {
  final SvgAsset icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? hoverColor;
  final double size;
  final double iconSize;
  final double radius;
  final Color? background;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.hoverColor,
    this.size = 38,
    this.iconSize = 18,
    this.radius = 12,
    this.background,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      iconSize: iconSize,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(background),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        overlayColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
              ? (hoverColor ?? c.text).withValues(alpha: 0.10)
              : null,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? BorderSide(color: c.lilac, width: 2)
              : BorderSide.none,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      icon: Builder(
        builder: (context) => icon.build(
          size: iconSize,
          color: onPressed == null
              ? (color ?? c.label).withValues(alpha: 0.35)
              : color ?? c.label,
        ),
      ),
    );
  }
}

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

enum AppButtonKind {
  primary,
  outlined,
  tonal,
  danger,
  softDanger,
  text,

  ///turns maintenance on (or off, from its banner)
  maintenance,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SvgAsset? icon;
  final Widget? leading;

  ///after the label (Open in Routes' external-link icon)
  final SvgAsset? trailing;
  final AppButtonKind kind;
  final double height;
  final double radius;
  final double fontSize;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.trailing,
    this.kind = AppButtonKind.primary,
    this.height = 40,
    this.radius = 12,
    this.fontSize = 14,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final (Color bg, Color fg, Color? border) = switch (kind) {
      AppButtonKind.primary => (c.lilac, c.onLilac, null),
      AppButtonKind.outlined => (Colors.transparent, c.text, c.outline),
      AppButtonKind.tonal => (c.raised, c.text, null),
      AppButtonKind.danger => (c.dangerFill, c.white, null),
      AppButtonKind.softDanger => (c.softRed, c.onSoftRed, null),
      AppButtonKind.text => (Colors.transparent, c.lilac, null),
      AppButtonKind.maintenance => (c.maintenance, c.onMaintenance, null),
    };
    final filled = kind != AppButtonKind.outlined && kind != AppButtonKind.text;
    final button = TextButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(bg),
        foregroundColor: WidgetStatePropertyAll(fg),
        overlayColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
              ? (filled
                    ? c.white.withValues(alpha: 0.07)
                    : c.text.withValues(alpha: 0.08))
              : null,
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        minimumSize: WidgetStatePropertyAll(Size(0, height)),
        fixedSize: WidgetStatePropertyAll(Size.fromHeight(height)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? BorderSide(color: c.lilac, width: 2)
              : border == null
              ? BorderSide.none
              : BorderSide(color: border),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ?leading,
          if (icon != null) icon!.build(size: 17, color: fg),
          if (icon != null || leading != null) const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              //text buttons are bold, as in the canvas (Clear all, Go to the login page)
              fontWeight: filled || kind == AppButtonKind.text
                  ? FontWeight.w600
                  : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!.build(size: 13, color: fg),
          ],
        ],
      ),
    );
    return onPressed == null ? Opacity(opacity: 0.38, child: button) : button;
  }
}

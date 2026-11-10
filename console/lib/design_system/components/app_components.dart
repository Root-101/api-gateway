import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

const Curve appEase = Cubic(0.2, 0, 0, 1);

///[duration], or none when the user prefers reduced motion
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

TextStyle monoStyle({
  double size = 13,
  Color? color,
  FontWeight weight = FontWeight.w400,
  double? height,
  double? letterSpacing,
}) => TextStyle(
  fontFamily: 'DMMono',
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: height,
  letterSpacing: letterSpacing,
);

enum AppButtonKind { primary, outlined, tonal, danger, softDanger, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SvgAsset? icon;
  final Widget? leading;
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
              fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
    return onPressed == null ? Opacity(opacity: 0.38, child: button) : button;
  }
}

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

///label + 48 px field + error line, the form field of every dialog
class AppField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final String? errorText;
  final bool hasError;
  final String? hint;
  final bool mono;
  final bool obscure;
  final bool readOnly;
  final bool autofocus;
  final Widget? suffix;
  final Color? fill;
  final String? autofillHint;
  final int? maxLength;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AppField({
    required this.label,
    required this.controller,
    this.required = false,
    this.errorText,
    this.hasError = false,
    this.hint,
    this.mono = false,
    this.obscure = false,
    this.readOnly = false,
    this.autofocus = false,
    this.suffix,
    this.fill,
    this.autofillHint,
    this.maxLength,
    this.formatters,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final failed = hasError || errorText != null;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    final textStyle = mono
        ? monoStyle(size: 14, color: readOnly ? c.textSecondary : c.text)
        : TextStyle(fontSize: 15, color: c.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label, required: required),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            obscureText: obscure,
            readOnly: readOnly,
            style: textStyle,
            cursorColor: c.lilac,
            autofillHints: autofillHint == null ? null : [autofillHint!],
            inputFormatters: [
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
              ...?formatters,
            ],
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: textStyle.copyWith(color: c.textTertiary),
              filled: true,
              fillColor: fill ?? c.field,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: border(failed ? c.danger : c.outline),
              focusedBorder: border(c.lilac, 2),
              suffixIcon: suffix,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: c.dangerText,
            ),
          ),
        ],
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FieldLabel(this.text, {this.required = false, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Text.rich(
      TextSpan(
        text: text,
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: c.lilac),
            ),
        ],
      ),
      style: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: c.label,
      ),
    );
  }
}

///search box with a clear button and, after a divider, optional chips inside the field
class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String clearLabel;
  final double height;
  final double fontSize;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;
  final List<Widget> chips;

  const AppSearchField({
    required this.controller,
    required this.hint,
    required this.clearLabel,
    required this.onClear,
    this.height = 48,
    this.fontSize = 15,
    this.onChanged,
    this.onSubmitted,
    this.chips = const [],
    super.key,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.only(left: 14, right: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? c.lilac : c.outlineField,
            width: _focused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            app.assets.icons.general.search.build(
              size: 19,
              color: c.textSecondary,
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                cursorColor: c.lilac,
                style: TextStyle(fontSize: widget.fontSize, color: c.text),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    fontSize: widget.fontSize,
                    color: c.textTertiary,
                  ),
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => widget.controller.text.isEmpty
                  ? const SizedBox.shrink()
                  : AppIconButton(
                      icon: app.assets.icons.actions.close,
                      tooltip: widget.clearLabel,
                      onPressed: widget.onClear,
                      size: 34,
                      iconSize: 17,
                      radius: 10,
                    ),
            ),
            if (widget.chips.isNotEmpty) ...[
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: c.outline,
              ),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final chip in widget.chips)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: chip,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

///page background: flat night color with a 48 px line grid
class GridBackground extends StatelessWidget {
  final Widget child;

  const GridBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GridPainter(app.colors.gridBg, app.colors.gridLine),
    child: child,
  );
}

class _GridPainter extends CustomPainter {
  final Color background;
  final Color line;

  _GridPainter(this.background, this.line);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()..color = line;
    for (double x = 47; x < size.width; x += 48) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);
    }
    for (double y = 47; y < size.height; y += 48) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class AppLogo extends StatelessWidget {
  final double width;
  final Color? color;

  const AppLogo({required this.width, this.color, super.key});

  @override
  Widget build(BuildContext context) => app.assets.icons.gateway.build(
    size: width,
    height: width * 23 / 24,
    color: color ?? app.colors.lilac,
  );
}

///the product name: always lowercase, DM Mono, with "api" in lilac
class AppWordmark extends StatelessWidget {
  final double size;
  final double letterSpacing;

  const AppWordmark({
    required this.size,
    required this.letterSpacing,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: 'api',
      style: TextStyle(color: app.colors.lilac),
      children: [
        TextSpan(
          text: '-gateway',
          style: TextStyle(color: app.colors.white),
        ),
      ],
    ),
    maxLines: 1,
    softWrap: false,
    style: monoStyle(
      size: size,
      weight: FontWeight.w500,
      height: 1,
      letterSpacing: letterSpacing,
    ),
  );
}

class AppTagline extends StatelessWidget {
  final double size;
  final double letterSpacing;

  const AppTagline({required this.size, this.letterSpacing = 0, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Text.rich(
      TextSpan(
        text: '${context.intl.app.taglineStart} ',
        children: [
          TextSpan(
            text: context.intl.app.taglineEnd,
            style: TextStyle(color: c.lilac),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: c.lilacText,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

///shimmering placeholder of the first load
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeleton({this.width, this.height = 12, this.radius = 6, super.key});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xff221f2e),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return box;
    return box
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1300.ms, color: const Color(0xff2e2a3d));
  }
}

///"FROM" / "TO" caption with its url, shared by the card, the preview and the delete dialog
class RouteUrlBlock extends StatelessWidget {
  final String caption;
  final String url;
  final bool accent;
  final double fontSize;
  final Color? urlColor;

  const RouteUrlBlock({
    required this.caption,
    required this.url,
    this.accent = false,
    this.fontSize = 13,
    this.urlColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CaptionText(caption, color: accent ? c.lilac : c.textTertiary),
        const SizedBox(height: 2),
        Text(
          url,
          style: monoStyle(
            size: fontSize,
            color: urlColor ?? c.text,
            height: 20 / 13,
          ),
        ),
      ],
    );
  }
}

///10-12 px uppercase caption used over urls and table columns
class CaptionText extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;

  const CaptionText(this.text, {this.color, this.size = 10, super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      height: 1.4,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: color ?? app.colors.textTertiary,
    ),
  );
}

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

///spinner sized for buttons and banners
class SmallSpinner extends StatelessWidget {
  final Color color;
  final double size;

  const SmallSpinner({required this.color, this.size = 14, super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}

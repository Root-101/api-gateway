import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class ThemeConfig {
  static ThemeData get theme {
    final c = app.colors;
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'DMSans',
      scaffoldBackgroundColor: c.night,
      colorScheme: ColorScheme.dark(
        primary: c.lilac,
        onPrimary: c.onLilac,
        surface: c.surface,
        onSurface: c.text,
        error: c.danger,
      ),
      focusColor: c.lilac.withValues(alpha: 0.12),
      hoverColor: c.text.withValues(alpha: 0.08),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.toast,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(fontSize: 12, color: c.text),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.lilac,
        selectionColor: c.lilac.withValues(alpha: 0.3),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? c.lilac : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onLilac),
        side: BorderSide(color: c.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.popup),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: c.outlineCard),
            ),
          ),
        ),
      ),
    );
  }
}

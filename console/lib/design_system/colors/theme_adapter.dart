import 'package:material_ui/material_ui.dart';

extension ThemeAdapter on ThemeData {
  Color Function({required Color light, required Color dark}) get color =>
      ({required dark, required light}) => isLight ? light : dark;

  bool get isLight => brightness == Brightness.light;

  bool get isDark => brightness == Brightness.dark;
}

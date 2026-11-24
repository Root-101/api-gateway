import 'package:material_ui/material_ui.dart';

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

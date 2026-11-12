import 'package:flutter/material.dart';

extension DarkenExtension on Color {
  Color darken(double factor) {
    HSLColor hsl = HSLColor.fromColor(this);
    HSLColor darkerHSL = hsl.withLightness(
      (hsl.lightness - factor).clamp(0.0, 1.0),
    );
    return darkerHSL.toColor();
  }

  Color brighten(double factor) {
    return darken(-1 * factor);
  }
}

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class ThemeConfig {
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: app.colors.primary.background1,
    brightness: Brightness.dark,
    fontFamily: 'DMSans',
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

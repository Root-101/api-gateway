import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class AppColors {
  static final AppColors _instance = AppColors._internal();

  AppColors._internal();

  factory AppColors() => _instance;

  PrimaryColor primary = PrimaryColor();
  NeutralColor neutral = NeutralColor();
}

class PrimaryColor {
  ///purple: 3D3065
  Color get purple => const Color(0xFF3D3065);

  Color get backgroundForm => background1.brighten(0.05);

  Color get background1 => const Color(0xff13111c);

  Color get background2 => const Color(0xff181622);

  Color get background3 => const Color(0xff2f2c3f);

  ///light blue / purple: 9484C5
  Color get primaryFaded => const Color(0xFF9484C5);

  ///brand color, ~orange: FDCA3C
  Color get secondary => const Color(0xFFFDCA3C);

  ///blue: 2652E0
  Color get tertiary => const Color(0xFF2652E0);

  ///red: E95450
  Color get error => const Color(0xFFE95450);

  ///red: EB3326
  Color get red => const Color(0xFFEB3326);

  ///red: 2CAA4A
  Color get green => const Color(0xFF2CAA4A);
}

class NeutralColor {
  Color get grey6 => const Color(0xff4b4b4b);

  Color get grey5 => const Color(0xff575562);

  Color get grey4 => const Color(0xff757481);

  Color get grey3 => const Color(0xffafafaf);

  Color get grey2 => const Color(0xffe5e5e5);

  Color get grey1 => const Color(0xfff7f7f7);

  ///AKA: white
  Color get white => const Color(0xffffffff);

  Color get transparent => Colors.transparent;
}

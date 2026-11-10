import 'package:flutter/material.dart';

///design tokens of the console identity (dark theme only)
class AppColors {
  static final AppColors _instance = AppColors._internal();

  AppColors._internal();

  factory AppColors() => _instance;

  //surfaces
  Color get night => const Color(0xff13111c);
  Color get gridBg => const Color(0xff121019);
  Color get gridLine => const Color(0x0dd0bcff);
  Color get rail => const Color(0xff16141f);
  Color get card => const Color(0xff181622);
  Color get surface => const Color(0xff1e1b2c);
  Color get field => const Color(0xff17151f);
  Color get raised => const Color(0xff2f2c3f);
  Color get popup => const Color(0xff211e2e);
  Color get toast => const Color(0xff2b2930);
  Color get barrier => const Color(0x9908070c);

  //borders
  Color get outline => const Color(0xff575562);
  Color get outlineCard => const Color(0xff3a3746);
  Color get outlineSoft => const Color(0xff2a2735);
  Color get outlineField => const Color(0xff49454f);
  Color get brandBorder => const Color(0xff2c2939);

  //action
  Color get lilac => const Color(0xffd0bcff);
  Color get onLilac => const Color(0xff381e72);
  Color get lilacMuted => const Color(0xff9d8fd0);
  Color get lilacText => const Color(0xffd9d2f2);
  Color get glow => const Color(0xff5d4999);
  Color get selected => const Color(0xff4a4458);
  Color get onSelected => const Color(0xffe8def8);

  //text
  Color get text => const Color(0xffe6e0e9);
  Color get label => const Color(0xffcac4d0);
  Color get textSecondary => const Color(0xffafafaf);
  Color get textTertiary => const Color(0xff8f8e9b);
  Color get white => const Color(0xffffffff);

  //status
  Color get success => const Color(0xffa5d6a7);
  Color get successDot => const Color(0xff4caf50);
  Color get info => const Color(0xff90caf9);
  Color get warn => const Color(0xffffe082);
  Color get orange => const Color(0xffffcc80);
  Color get softRed => const Color(0xfff2b8b5);
  Color get onSoftRed => const Color(0xff601410);
  Color get danger => const Color(0xffe95450);
  Color get dangerText => const Color(0xffff8a86);
  Color get dangerFill => const Color(0xffc8352f);
  Color get offline => const Color(0xfffdca3c);

  ///pill colors of an HTTP status, by its family
  ({Color bg, Color fg}) statusTone(int status) => switch (status ~/ 100) {
    2 => (bg: successDot.withValues(alpha: 0.14), fg: success),
    3 => (bg: info.withValues(alpha: 0.14), fg: info),
    4 => (bg: const Color(0x24ffd54f), fg: warn),
    5 => (bg: softRed.withValues(alpha: 0.16), fg: softRed),
    _ => (bg: raised, fg: label),
  };

  Color methodColor(String method) => switch (method) {
    'GET' => success,
    'POST' => info,
    'PUT' || 'PATCH' => orange,
    'DELETE' => softRed,
    _ => label,
  };
}

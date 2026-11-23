import 'package:material_ui/material_ui.dart';

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
  Color get popupLilac => const Color(0xff2a2540);
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

  ///an empty value shown in its place, like the route form preview
  Color get textPlaceholder => const Color(0xff6f6c7b);
  Color get white => const Color(0xffffffff);

  //one use each, named after it
  ///a skeleton block
  Color get skeleton => const Color(0xff221f2e);

  ///the shine that runs over a skeleton
  Color get skeletonShine => const Color(0xff2e2a3d);

  ///the round icon of an error toast or a delete confirmation
  Color get dangerIcon => const Color(0xff8c1d18);

  ///the glyph on [dangerIcon]
  Color get onDangerIcon => const Color(0xfff9dedc);

  ///the round icon of a success toast
  Color get successIcon => const Color(0xff1f4d25);

  ///behind a dialog opened over another one (the calendar)
  Color get barrierSoft => const Color(0x7308070c);

  ///behind the session expired dialog, which can't be left
  Color get barrierStrong => const Color(0xb80a090f);

  ///today in the calendar
  Color get outlineToday => const Color(0xff938f99);

  ///a field inside a dialog (the exact status code)
  Color get fieldDeep => const Color(0xff0f0d16);

  ///a branch of the map that only redirects
  Color get redirect => const Color(0xff8b80c0);

  ///a map node in maintenance
  Color get maintenanceSurface => const Color(0xff221b1f);

  ///a map node whose health check fails
  Color get downSurface => const Color(0xff1f1519);

  ///the track of an on health check slide switch
  Color get successDeep => const Color(0xff0f3a14);

  ///the track of an on rate limit slide switch
  Color get infoDeep => const Color(0xff0b2b45);

  ///shadow of a small control
  Color get shadowSoft => const Color(0x59000000);

  ///shadow of a map node
  Color get shadow => const Color(0x73000000);

  ///shadow of a tooltip
  Color get shadowStrong => const Color(0x80000000);

  //status
  Color get success => const Color(0xffa5d6a7);
  Color get successDot => const Color(0xff4caf50);
  Color get info => const Color(0xff90caf9);
  Color get orange => const Color(0xffffcc80);
  Color get warn => const Color(0xffffe082);
  Color get softRed => const Color(0xfff2b8b5);
  Color get onSoftRed => const Color(0xff601410);
  Color get danger => const Color(0xffe95450);
  Color get dangerText => const Color(0xffff8a86);
  Color get dangerFill => const Color(0xffc8352f);
  Color get offline => const Color(0xfffdca3c);

  ///maintenance mode (a route or the whole gateway answering 503)
  Color get maintenance => const Color(0xffffb68a);
  Color get onMaintenance => const Color(0xff4a1f00);

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

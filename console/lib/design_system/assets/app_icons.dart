import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

///line icons (24 px grid, 2 px stroke, round caps), inlined so they all share one style
class AppIcons {
  const AppIcons();

  final ActionsIcons actions = const ActionsIcons();
  final GeneralIcons general = const GeneralIcons();
  final LanguageIcons language = const LanguageIcons();

  ///the brand mark: filled dot on top, three hollow dots below
  SvgAsset get gateway => const SvgAsset(
    '<path d="M12 6v10.5"/><path d="M12 9c0 2.2-8.5 1.3-8.5 4.2v3.3"/><path d="M12 9c0 2.2 8.5 1.3 8.5 4.2v3.3"/><circle cx="12" cy="3.5" r="2.5" fill="#000"/><circle cx="3.5" cy="19" r="2.5"/><circle cx="12" cy="19" r="2.5"/><circle cx="20.5" cy="19" r="2.5"/>',
    viewBox: '0 0 24 23',
  );

  SvgAsset get routes => const SvgAsset(
    '<circle cx="6" cy="19" r="3"/><path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15"/><circle cx="18" cy="5" r="3"/>',
  );

  SvgAsset get logs => const SvgAsset(
    '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/>',
  );
}

class ActionsIcons {
  const ActionsIcons();

  SvgAsset get add =>
      const SvgAsset('<path d="M5 12h14"/><path d="M12 5v14"/>');

  SvgAsset get edit => const SvgAsset(
    '<path d="M21.17 6.81a1 1 0 0 0-3.99-3.99L3.84 16.17a2 2 0 0 0-.5.83l-1.32 4.35a.5.5 0 0 0 .62.62l4.35-1.32a2 2 0 0 0 .83-.5z"/><path d="m15 5 4 4"/>',
  );

  SvgAsset get delete => const SvgAsset(
    '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><path d="M10 11v6"/><path d="M14 11v6"/>',
  );

  SvgAsset get upload => const SvgAsset(
    '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m17 8-5-5-5 5"/><path d="M12 3v12"/>',
  );

  SvgAsset get download => const SvgAsset(
    '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 10 5 5 5-5"/><path d="M12 15V3"/>',
  );

  SvgAsset get reload => const SvgAsset(
    '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/>',
  );

  SvgAsset get close =>
      const SvgAsset('<path d="M18 6 6 18"/><path d="m6 6 12 12"/>');

  SvgAsset get logout => const SvgAsset(
    '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
  );

  SvgAsset get duplicate => const SvgAsset(
    '<rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>',
  );

  SvgAsset get arrowRight =>
      const SvgAsset('<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>');
}

class GeneralIcons {
  const GeneralIcons();

  SvgAsset get folderOpen => const SvgAsset(
    '<path d="m6 14 1.5-2.9A2 2 0 0 1 9.24 10H20a2 2 0 0 1 1.94 2.5l-1.54 6a2 2 0 0 1-1.95 1.5H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3.9a2 2 0 0 1 1.69.9l.81 1.2a2 2 0 0 0 1.67.9H18a2 2 0 0 1 2 2v2"/>',
  );

  SvgAsset get filter =>
      const SvgAsset('<path d="M22 3H2l8 9.46V19l4 2v-8.54L22 3z"/>');

  SvgAsset get search => const SvgAsset(
    '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  );

  SvgAsset get eye => const SvgAsset(
    '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
  );

  SvgAsset get eyeOff => const SvgAsset(
    '<path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.53 13.53 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><path d="M2 2l20 20"/>',
  );

  SvgAsset get alertCircle => const SvgAsset(
    '<circle cx="12" cy="12" r="10"/><path d="M12 8v4"/><path d="M12 16h.01"/>',
  );

  SvgAsset get info => const SvgAsset(
    '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  );

  SvgAsset get alertTriangle => const SvgAsset(
    '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  );

  SvgAsset get check => const SvgAsset('<path d="M20 6 9 17l-5-5"/>');

  SvgAsset get checkCircle => const SvgAsset(
    '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
  );

  SvgAsset get fileUp => const SvgAsset(
    '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M12 12v6"/><path d="m15 15-3-3-3 3"/>',
  );

  SvgAsset get inbox => const SvgAsset(
    '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>',
  );

  SvgAsset get calendar => const SvgAsset(
    '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/>',
  );

  SvgAsset get chevronDown => const SvgAsset('<path d="m6 9 6 6 6-6"/>');

  SvgAsset get chevronLeft => const SvgAsset('<path d="m15 18-6-6 6-6"/>');

  SvgAsset get chevronRight => const SvgAsset('<path d="m9 18 6-6-6-6"/>');

  SvgAsset get lock => const SvgAsset(
    '<rect x="5" y="10.5" width="14" height="9.5" rx="2"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
  );

  SvgAsset get wifiOff => const SvgAsset(
    '<path d="M2 8.5a15 15 0 0 1 20 0"/><path d="M5 12a10 10 0 0 1 9.5-2.6"/><path d="M8.5 15.5a5 5 0 0 1 4.5-1.2"/><path d="M12 19h.01"/><path d="M3 3l18 18"/>',
  );
}

class LanguageIcons {
  const LanguageIcons();

  SvgAsset get en => const SvgAsset(
    '<path fill="#EEE" stroke="none" d="M32 5H4C1.791 5 0 6.791 0 9v18c0 2.209 1.791 4 4 4h28c2.209 0 4-1.791 4-4V9c0-2.209-1.791-4-4-4z"/><path fill="#CE1124" stroke="none" d="M21 5h-6v10H0v6h15v10h6V21h15v-6H21z"/>',
    viewBox: '0 0 36 36',
    colored: true,
  );

  SvgAsset get es => const SvgAsset(
    '<path fill="#C60A1D" stroke="none" d="M32 5H4C1.791 5 0 6.791 0 9v18c0 2.209 1.791 4 4 4h28c2.209 0 4-1.791 4-4V9c0-2.209-1.791-4-4-4z"/><path fill="#FFC400" stroke="none" d="M0 13h36v10H0z"/>',
    viewBox: '0 0 36 36',
    colored: true,
  );
}

class SvgAsset {
  final String body;
  final String viewBox;

  ///multi-color artwork (flags): never tinted
  final bool colored;

  const SvgAsset(this.body, {this.viewBox = '0 0 24 24', this.colored = false});

  Widget build({double size = 24, double? height, Color? color}) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox" fill="none" '
      'stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      '$body</svg>',
      width: size,
      height: height ?? size,
      colorFilter: !colored && color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }
}

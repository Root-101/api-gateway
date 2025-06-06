import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class CustomAppBar {
  static AppBar build({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    PreferredSizeWidget? bottom,
    double? scrolledUnderElevation,
  }) {
    return AppBar(
      scrolledUnderElevation: scrolledUnderElevation ?? 5.0,
      shadowColor:
          scrolledUnderElevation == 0
              ? app.colors.neutral.transparent
              : app.colors.neutral.grey5.withAlpha(35),
      surfaceTintColor: app.colors.neutral.white,
      leading: leading,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottom?.preferredSize.height ?? 0 + 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            bottom ?? const SizedBox.shrink(),
            Divider(
              height: 0.5,
              color: app.colors.neutral.grey5.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
      backgroundColor: app.theme.scaffoldBackgroundColor,
      title: Text(title),
      actions: actions,
    );
  }
}

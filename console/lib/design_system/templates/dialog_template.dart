import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///the dialog of the console: header with close, scrollable body and an optional footer.
///Focus is kept inside by the modal route and returns to the opener when it closes
class DialogTemplate extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double width;
  final Widget body;
  final Widget? footer;

  ///the long dialogs hang from the top, the short ones are centered
  final Alignment alignment;
  final FocusNode? closeFocusNode;
  final VoidCallback? onClose;

  const DialogTemplate({
    required this.title,
    required this.body,
    this.subtitle,
    this.width = 580,
    this.footer,
    this.alignment = Alignment.topCenter,
    this.closeFocusNode,
    this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return DialogFrame(
      width: width,
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 12, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.raised)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          height: 28 / 20,
                          fontWeight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: app.assets.icons.actions.close,
                  tooltip: context.intl.actions.close,
                  size: 44,
                  iconSize: 20,
                  focusNode: closeFocusNode,
                  autofocus: closeFocusNode != null,
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: body,
            ),
          ),
          if (footer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.raised)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

///surface of a dialog, for the ones with their own layout
class DialogFrame extends StatelessWidget {
  final double width;
  final Alignment alignment;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final Widget child;

  const DialogFrame({
    required this.child,
    this.width = 580,
    this.alignment = Alignment.center,
    this.radius = 22,
    this.color,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Material(
            color: color ?? c.surface,
            clipBehavior: Clip.antiAlias,
            elevation: 24,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(color: borderColor ?? c.raised),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

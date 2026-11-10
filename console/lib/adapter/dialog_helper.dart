import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class DialogHelper {
  static final DialogHelper _instance = DialogHelper._internal();

  DialogHelper._internal();

  factory DialogHelper() => _instance;

  static const Duration _transitionDuration = Duration(milliseconds: 200);

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Widget dialog,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return dialog;
    final t = appEase.transform(animation.value);
    return Opacity(
      opacity: animation.value,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - t)),
        child: Transform.scale(scale: 0.98 + 0.02 * t, child: dialog),
      ),
    );
  }

  Future<T?> open<T>({
    required Widget dialog,
    BuildContext? context,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context ?? app.context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? app.colors.barrier,
      barrierLabel: '',
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionDuration: _transitionDuration,
      transitionBuilder: (context, animation, secondaryAnimation, _) =>
          _transition(context, animation, dialog),
    );
  }
}

/// Same dialog as [DialogHelper.open] but as a go_router page: it has its own
/// url and closing it (button, barrier or browser back) goes back to the parent
class DialogPage<T> extends Page<T> {
  final Widget dialog;

  const DialogPage({required this.dialog, super.key});

  @override
  Route<T> createRoute(BuildContext context) => RawDialogRoute<T>(
    settings: this,
    barrierDismissible: true,
    barrierColor: app.colors.barrier,
    barrierLabel: '',
    transitionDuration: DialogHelper._transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) =>
        const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, _) =>
        DialogHelper._transition(context, animation, dialog),
  );
}

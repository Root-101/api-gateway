import 'package:console/app_exporter.dart';
import 'package:flutter/cupertino.dart';

class DialogHelper {
  static final DialogHelper _instance = DialogHelper._internal();

  DialogHelper._internal();

  factory DialogHelper() => _instance;

  static const Duration _transitionDuration = Duration(milliseconds: 200);

  static Widget _transition(Animation<double> animation, Widget dialog) =>
      Transform.scale(
        scale: animation.value,
        child: Opacity(opacity: animation.value, child: dialog),
      );

  Future open({
    required Widget dialog,
    BuildContext? context,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog(
      context: context ?? app.context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionDuration: _transitionDuration,
      transitionBuilder: (context, animation, secondaryAnimation, _) =>
          _transition(animation, dialog),
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
    barrierLabel: '',
    transitionDuration: DialogHelper._transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) =>
        const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, _) =>
        DialogHelper._transition(animation, dialog),
  );
}

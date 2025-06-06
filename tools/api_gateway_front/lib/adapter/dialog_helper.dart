import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/cupertino.dart';

class DialogHelper {
  static final DialogHelper _instance = DialogHelper._internal();

  DialogHelper._internal();

  factory DialogHelper() => _instance;

  Future open({
    required Widget dialog,
    BuildContext? context,
    bool barrierDismissible = true,
  }) async {
    showGeneralDialog(
      context: context ?? app.context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        return Transform.scale(
          scale: animation.value,
          child: Opacity(opacity: animation.value, child: dialog),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

typedef ToastData = ({String message, bool error, int id});

///toasts: bottom right, one at a time, gone after 3.2 s or with their close button.
///Shown by [ToastHost], which wraps the whole app (MaterialApp.builder)
class SnackBarAdapter {
  static final SnackBarAdapter _instance = SnackBarAdapter._internal();

  SnackBarAdapter._internal();

  factory SnackBarAdapter() => _instance;

  final ValueNotifier<ToastData?> current = ValueNotifier(null);
  Timer? _timer;
  int _id = 0;

  void showSuccess({required String message}) => _show(message, error: false);

  void showError({required String message}) => _show(message, error: true);

  void dismiss() {
    _timer?.cancel();
    current.value = null;
  }

  void _show(String message, {required bool error}) {
    _timer?.cancel();
    current.value = (message: message, error: error, id: ++_id);
    _timer = Timer(const Duration(milliseconds: 3200), dismiss);
  }
}

class ToastHost extends StatelessWidget {
  final Widget child;

  const ToastHost({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 20,
          bottom: 20,
          child: ValueListenableBuilder<ToastData?>(
            valueListenable: app.snack.current,
            builder: (context, toast, _) => toast == null
                ? const SizedBox.shrink()
                : _Toast(key: ValueKey(toast.id), data: toast),
          ),
        ),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  final ToastData data;

  const _Toast({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final error = data.error;
    final toast = Semantics(
      liveRegion: true,
      child: Material(
        color: c.toast,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.outlineCard),
        ),
        child: Container(
          width: 360,
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: error
                      ? const Color(0xff8c1d18)
                      : const Color(0xff1f4d25),
                  shape: BoxShape.circle,
                ),
                child:
                    (error
                            ? app.assets.icons.general.alertTriangle
                            : app.assets.icons.general.check)
                        .build(
                          size: 20,
                          color: error ? const Color(0xfff9dedc) : c.success,
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
              ),
              //no IconButton: its tooltip needs an Overlay, and this sits above the navigator's
              Semantics(
                button: true,
                label: context.intl.actions.dismiss,
                child: InkWell(
                  onTap: app.snack.dismiss,
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Center(
                      child: app.assets.icons.actions.close.build(
                        size: 17,
                        color: c.label,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    //implicit animation: flutter_animate's .animate() stayed at opacity 0 above the navigator
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion(context, const Duration(milliseconds: 250)),
      curve: appEase,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: toast,
    );
  }
}

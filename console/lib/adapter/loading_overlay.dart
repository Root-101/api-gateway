import 'package:flutter/foundation.dart';

///the blur with a spinner over the whole app while an action runs. Drawn by [ToastHost], under its
///toast: the loader_overlay package painted above the app and the toast that follows never showed
class LoadingOverlay {
  static final LoadingOverlay _instance = LoadingOverlay._internal();

  LoadingOverlay._internal();

  factory LoadingOverlay() => _instance;

  final ValueNotifier<bool> visible = ValueNotifier(false);

  void show() => visible.value = true;

  bool isShowing() => visible.value;

  void hide() => visible.value = false;
}

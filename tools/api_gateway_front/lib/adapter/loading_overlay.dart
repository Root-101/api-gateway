import 'dart:ui';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

class LoadingOverlay {
  static final LoadingOverlay _instance = LoadingOverlay._internal();

  LoadingOverlay._internal();

  factory LoadingOverlay() => _instance;

  static GlobalLoaderOverlay buildGlobal({required Widget child}) {
    return GlobalLoaderOverlay(
      overlayColor: Colors.transparent,
      overlayWidgetBuilder:
          //TODO: improve
          (progress) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      child: child,
    );
  }

  void show({BuildContext? context}) {
    BuildContext safeContext = context ?? app.context;
    safeContext.loaderOverlay.show();
  }

  bool isShowing({BuildContext? context}) {
    BuildContext safeContext = context ?? app.context;
    return safeContext.loaderOverlay.visible;
  }

  void hide({BuildContext? context}) {
    BuildContext safeContext = context ?? app.context;
    safeContext.loaderOverlay.hide();
  }
}

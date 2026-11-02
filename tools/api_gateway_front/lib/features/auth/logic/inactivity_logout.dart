import 'dart:async';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

///logs out after [timeout] without pointer or keyboard activity (credentials otherwise live in memory forever)
class InactivityLogout {
  static DateTime _lastActivity = DateTime.now();

  static void start({required AuthCubit auth, required Duration timeout}) {
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      (_) => _lastActivity = DateTime.now(),
    );
    HardwareKeyboard.instance.addHandler((_) {
      _lastActivity = DateTime.now();
      return false; //don't consume the key
    });
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (auth.isLoggedIn &&
          DateTime.now().difference(_lastActivity) >= timeout) {
        auth.logout();
      }
    });
  }
}

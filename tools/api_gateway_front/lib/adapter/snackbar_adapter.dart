import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class SnackBarAdapter {
  static final SnackBarAdapter _instance = SnackBarAdapter._internal();

  SnackBarAdapter._internal();

  factory SnackBarAdapter() => _instance;

  void showSuccess({required String message, required BuildContext context}) {
    showTopSnackBar(
      Overlay.of(context),
      snackBarPosition: SnackBarPosition.bottom,
      padding: EdgeInsets.only(
        right: app.dimensions.padding.l,
        bottom: app.dimensions.padding.l,
        left: MediaQuery.of(context).size.width * 0.75,
      ),
      CustomSnackBar.success(
        borderRadius: app.dimensions.border.borderRadius.m,
        textStyle: app.textTheme.titleMedium!.copyWith(
          color: app.colors.neutral.white,
        ),
        iconRotationAngle: -15,
        backgroundColor: app.colors.primary.green,
        message: message,
      ),
    );
  }

  void showError({required String message, required BuildContext context}) {
    showTopSnackBar(
      Overlay.of(context),
      snackBarPosition: SnackBarPosition.bottom,
      padding: EdgeInsets.only(
        right: app.dimensions.padding.l,
        bottom: app.dimensions.padding.l,
        left: MediaQuery.of(context).size.width * 0.75,
      ),
      CustomSnackBar.error(
        borderRadius: app.dimensions.border.borderRadius.m,
        textStyle: app.textTheme.titleMedium!.copyWith(
          color: app.colors.neutral.white,
        ),
        iconRotationAngle: -15,
        backgroundColor: app.colors.primary.red,
        message: message,
      ),
    );
  }
}

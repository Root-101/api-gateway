import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onPressed;
  final String? buttonText;

  const ErrorPage({
    this.errorMessage,
    this.onPressed,
    this.buttonText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          icon: app.assets.icons.general.alertTriangle,
          title: errorMessage ?? context.intl.errors.genericError,
          action: onPressed == null
              ? null
              : AppButton(
                  label: buttonText ?? context.intl.actions.tryAgain,
                  onPressed: onPressed,
                ),
        ),
      ),
    );
  }
}

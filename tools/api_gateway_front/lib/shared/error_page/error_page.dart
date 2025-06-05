import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class ErrorPage extends StatefulWidget {
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
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: app.dimensions.padding.xxl,
                ),
                child: Text(
                  widget.errorMessage ?? app.intl.genericError,
                  style: app.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              if (widget.onPressed != null) ...[
                (2 * app.dimensions.padding.xxl).gap(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2 * app.dimensions.padding.xxl,
                  ),
                  child: PrimaryButton.primary(
                    title: widget.buttonText ?? app.intl.tryAgain,
                    onPressed: widget.onPressed ?? () {},
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FormComponentTemplate extends StatelessWidget {
  final String? label;
  final String? errorText;
  final Widget child;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const FormComponentTemplate({
    required this.child,
    this.label,
    this.errorText,
    this.height,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color safeBackgroundColor = app.colors.primary.backgroundForm;

    Color safeBorderColor = app.colors.neutral.grey2;
    double safeBorderWidth = app.dimensions.border.width.def;

    TextStyle labelTextStyle = app.textTheme.labelMedium!.copyWith(
      color: safeBorderColor,
    );

    Color errorColor = app.colors.primary.red;
    TextStyle errorTextStyle = app.textTheme.labelMedium!.copyWith(
      color: errorColor,
    );

    BorderRadius safeBorderRadius = app.dimensions.border.borderRadius.def;
    BorderRadius safeErrorBorderRadius = app.dimensions.border.borderRadius.xs;

    BorderSide smallSide = BorderSide(
      color: errorText?.isNotEmpty == true ? errorColor : safeBorderColor,
      width: safeBorderWidth,
    );
    BorderSide fatSide = BorderSide(
      color: errorText?.isNotEmpty == true ? errorColor : safeBorderColor,
      width: 2 * safeBorderWidth,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label?.isNotEmpty == true) ...[
          Text(label!, style: labelTextStyle),
          app.dimensions.padding.xs.gap(),
        ],
        _wrapShake(
          shake: errorText?.isNotEmpty == true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: smallSide,
                    left: smallSide,
                    right: smallSide,
                    bottom: fatSide,
                  ),
                  borderRadius:
                      errorText?.isNotEmpty == true
                          ? safeErrorBorderRadius
                          : borderRadius ?? safeBorderRadius,
                  color: safeBackgroundColor,
                ),
                height: height,
                width: double.infinity,
                child: child,
              ),
              if (errorText?.isNotEmpty == true)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: app.dimensions.padding.m,
                    vertical: app.dimensions.padding.xs,
                  ),
                  child: Text(errorText!, style: errorTextStyle),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wrapShake({required Widget child, required bool shake}) {
    return shake ? child.animate(key: UniqueKey()).shakeX() : child;
  }
}

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class FormDialogTemplate extends StatelessWidget {
  static void open({
    required String title,
    required Widget child,
    BuildContext? context,
    double? w,
    double? h,
  }) {
    app.dialog.open(
      dialog: FormDialogTemplate(title: title, w: w, h: h, child: child),
      context: context,
    );
  }

  final double? w;
  final double? h;

  final String title;
  final Widget child;

  const FormDialogTemplate({
    required this.title,
    required this.child,
    this.w,
    this.h,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 50.0,
      alignment: Alignment.center,
      child: SizedBox(
        width: w ?? 550,
        height: h ?? app.mediaQuery.size.height - app.dimensions.padding.xxl,
        child: ClipRRect(
          borderRadius: app.dimensions.border.borderRadius.s,
          child: Scaffold(
            backgroundColor: app.colors.primary.backgroundForm,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: 0,
                    child: Center(
                      child: Text(title, style: app.textTheme.titleMedium),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    top: 0,
                    right: app.dimensions.padding.xs,
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          app.navigator.pop();
                        },
                        icon: app.assets.icons.actions.close.build(
                          size: 18,
                          color: app.colors.neutral.grey2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            body: child,
          ),
        ),
      ),
    );
  }
}

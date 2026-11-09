import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app.colors.neutral.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(context.intl.common.loading),
            app.dimensions.padding.m.gap(),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

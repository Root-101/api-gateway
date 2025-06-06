import 'package:api_gateway_front/app_exporter.dart';
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
            Text(app.intl.loading),
            app.dimensions.padding.m.gap(),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

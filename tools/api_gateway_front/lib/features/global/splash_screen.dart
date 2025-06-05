import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  static const String splashImageUrl = 'assets/app/app_splashscreen_full.png';

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.theme,
      builder:
          (context, child) => Scaffold(
            body: SizedBox.expand(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        app.assets.icons.gateway.build(
                          color: app.colors.neutral.white,
                          size: 148,
                        ),
                        app.dimensions.padding.xxl.gap(),
                        Text(
                          'Api-Gateway',
                          style: TextTheme.of(context).headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Center(
                      child: Text(
                        'With ♥ from Maple',
                        style: TextTheme.of(context).titleSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

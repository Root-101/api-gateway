import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    //no navigator or intl yet: plain English text
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.theme,
      home: Scaffold(
        body: GridBackground(
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(width: 120),
                    const SizedBox(height: 28),
                    const AppWordmark(size: 52, letterSpacing: -2),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: 'One route to ',
                        children: [
                          TextSpan(
                            text: 'rule them all',
                            style: TextStyle(color: c.lilac),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: c.lilacText,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          color: c.lilac,
                          backgroundColor: c.brandBorder,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connecting to the gateway…',
                      style: TextStyle(fontSize: 14, color: c.textTertiary),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 24,
                  child: FutureBuilder<String?>(
                    future: appVersion,
                    builder: (context, snapshot) => Text(
                      snapshot.data == null ? '' : 'v${snapshot.data}',
                      style: monoStyle(
                        size: 12,
                        color: const Color(0xff6f6c7b),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

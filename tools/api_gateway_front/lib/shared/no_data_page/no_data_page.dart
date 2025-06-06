import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class NoDataPage extends StatelessWidget {
  const NoDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            app.dimensions.padding.xxl.gap(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: app.dimensions.padding.xxl,
              ),
              child: Text(
                app.intl.noData,
                style: app.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            (5 * app.dimensions.padding.xxl).gap(),
          ],
        ),
      ),
    );
  }
}

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class LogDetailsScreen extends StatelessWidget {
  static void open(HttpLogModel log) {
    DialogTemplate.open(
      title: app.intl.logDetails,
      child: LogDetailsScreen(log: log),
    );
  }

  final HttpLogModel log;

  const LogDetailsScreen({required this.log, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(app.dimensions.padding.l),
      child: Column(children: [Text(log.route?.routeName ?? ' no name')]),
    );
  }
}

import 'package:api_gateway_front/app_exporter.dart';

class AppAssets {
  static final AppAssets _instance = AppAssets._internal();

  AppAssets._internal();

  factory AppAssets() => _instance;

  final AppIcons icons = const AppIcons();
}

import 'package:flutter/material.dart';

class AppDimensions {
  static final AppDimensions _instance = AppDimensions._internal();

  AppDimensions._internal();

  factory AppDimensions() => _instance;

  AppBorder border = AppBorder();

  AppPadding padding = AppPadding();
}

class AppBorder {
  final AppRadius radius = AppRadius();
  late final AppBorderRadius borderRadius;
  final AppBorderWidth width = AppBorderWidth();
  final AppBorderWidth side = AppBorderWidth();

  AppBorder() {
    borderRadius = AppBorderRadius(radius);
  }
}

class AppRadius {
  Radius get xs => const Radius.circular(7.5);

  Radius get s => const Radius.circular(10);

  Radius get sm => const Radius.circular(12.5);

  Radius get m => const Radius.circular(15);

  Radius get xm => const Radius.circular(17.5);

  Radius get l => const Radius.circular(20);

  Radius get xl => const Radius.circular(22.5);

  Radius get def => m;
}

class AppBorderRadius {
  final AppRadius radius;

  AppBorderRadius(this.radius);

  BorderRadius get xs => BorderRadius.all(radius.xs);

  BorderRadius get s => BorderRadius.all(radius.s);

  BorderRadius get sm => BorderRadius.all(radius.sm);

  BorderRadius get m => BorderRadius.all(radius.m);

  BorderRadius get xm => BorderRadius.all(radius.xm);

  BorderRadius get l => BorderRadius.all(radius.l);

  BorderRadius get xl => BorderRadius.all(radius.xl);

  BorderRadius get def => m;
}

class AppBorderWidth {
  ///1.0
  double get s => 1;

  ///1.5
  double get m => 1.5;

  ///2.0
  double get l => 2.0;

  ///m = 1.5
  double get def => m;
}

class AppPadding {
  ///4.0
  double get xs => 4.0;

  ///8.0
  double get s => 8.0;

  ///10.0
  double get sm => 10.0;

  ///12.0
  double get m => 12.0;

  ///16.0
  double get l => 16.0;

  ///20.0
  double get xl => 20.0;

  ///24.0
  double get xxl => 24.0;

  ///medium: 12.0
  double get def => m;
}

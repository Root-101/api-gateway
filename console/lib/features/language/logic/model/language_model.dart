import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class LanguageModel {
  final SvgAsset icon;
  final String key;
  final String name;

  LanguageModel({required this.icon, required this.key, required this.name});

  Locale get locale => Locale(key);

  @override
  String toString() {
    return 'LanguageModel[key = $key, name = $name]';
  }

  @override
  int get hashCode {
    return key.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is LanguageModel) {
      return key == other.key;
    }
    return false;
  }
}

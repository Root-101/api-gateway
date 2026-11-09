import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageListener extends StatelessWidget {
  final Widget Function(Locale locale) onLanguageChangeBuilder;

  const LanguageListener({required this.onLanguageChangeBuilder, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        return onLanguageChangeBuilder(state.current.locale);
      },
    );
  }
}

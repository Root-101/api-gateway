import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageWidget extends CubitView<LanguageCubit> {
  const LanguageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        return PopupMenuButton<String>(
          onSelected: (value) {
            cubit.changeLanguageKey(languageKey: value);
          },
          itemBuilder:
              (context) =>
                  state.allLanguages
                      .map((e) => PopupMenuItem(value: e.key, child: _build(e)))
                      .toList(),
          child: _build(state.current),
        );
      },
    );
  }

  Widget _build(LanguageModel language) {
    return Container(
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.xs,
        border: Border.all(color: app.colors.neutral.grey5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            language.icon.build(),
            app.dimensions.padding.s.gap(),
            Text(
              language.key.toUpperCase(),
              style: app.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

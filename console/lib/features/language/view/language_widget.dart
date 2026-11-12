import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageWidget extends CubitView<LanguageCubit> {
  ///in the rail: only the 56 px button, and the menu opens to its right
  final bool compact;

  const LanguageWidget({this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        return MenuAnchor(
          alignmentOffset: compact ? const Offset(64, 0) : const Offset(0, 8),
          menuChildren: [
            for (final language in state.allLanguages)
              SizedBox(
                width: 188,
                child: MenuItemButton(
                  autofocus: language == state.allLanguages.first,
                  onPressed: () =>
                      cubit.changeLanguageKey(languageKey: language.key),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      language == state.current ? c.raised : Colors.transparent,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    minimumSize: const WidgetStatePropertyAll(Size(188, 40)),
                  ),
                  leadingIcon: language.icon.build(size: 20),
                  trailingIcon: language == state.current
                      ? app.assets.icons.general.check.build(
                          size: 16,
                          color: c.lilac,
                        )
                      : null,
                  child: Text(
                    language.name,
                    style: TextStyle(fontSize: 14, color: c.text),
                  ),
                ),
              ),
          ],
          builder: (context, controller, _) => Tooltip(
            message: context.intl.app.languageLabel(name: state.current.name),
            child: Material(
              color: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: c.outlineField),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                child: Container(
                  height: 40,
                  width: compact ? 56 : null,
                  padding: compact
                      ? null
                      : const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      state.current.icon.build(size: compact ? 18 : 20),
                      SizedBox(width: compact ? 4 : 8),
                      Text(
                        state.current.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        app.assets.icons.general.chevronDown.build(
                          size: 14,
                          color: c.label,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

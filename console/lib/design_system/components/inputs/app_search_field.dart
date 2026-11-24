import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///search box with a clear button and, after a divider, optional chips inside the field
class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String clearLabel;
  final double height;
  final double fontSize;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;
  final List<Widget> chips;

  const AppSearchField({
    required this.controller,
    required this.hint,
    required this.clearLabel,
    required this.onClear,
    this.height = 48,
    this.fontSize = 15,
    this.onChanged,
    this.onSubmitted,
    this.chips = const [],
    super.key,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.only(left: 14, right: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? c.lilac : c.outlineField,
            width: _focused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            app.assets.icons.general.search.build(
              size: 19,
              color: c.textSecondary,
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                cursorColor: c.lilac,
                style: TextStyle(fontSize: widget.fontSize, color: c.text),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    fontSize: widget.fontSize,
                    color: c.textTertiary,
                  ),
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => widget.controller.text.isEmpty
                  ? const SizedBox.shrink()
                  : AppIconButton(
                      icon: app.assets.icons.actions.close,
                      tooltip: widget.clearLabel,
                      onPressed: widget.onClear,
                      size: 34,
                      iconSize: 17,
                      radius: 10,
                    ),
            ),
            //the chips (and their divider) sit against the right edge, the free space stays on the left
            if (widget.chips.isNotEmpty)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: c.outline,
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final chip in widget.chips)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: chip,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';

class EMTextSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;
  final int delay;
  final ValueChanged<String> onSearch;
  final BorderRadius? borderRadius;
  final Widget? extraSuffix;

  const EMTextSearchField({
    required this.controller,
    required this.onSearch,
    this.borderRadius,
    this.hint,
    this.delay = 500,
    this.extraSuffix,
    super.key,
  });

  @override
  State<EMTextSearchField> createState() => _EMTextSearchFieldState();
}

class _EMTextSearchFieldState extends State<EMTextSearchField> {
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.delay), () {
      widget.onSearch(query);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildNativeSuffix() {
      return Visibility(
        visible: widget.controller.text.isNotEmpty,
        child: IconButton(
          onPressed: () {
            widget.controller.clear();
            widget.onSearch('');
            setState(() {});
          },
          icon: app.assets.icons.general.close.build(
            color: app.colors.neutral.white,
          ),
        ),
      );
    }

    return AppTextInput.textField(
      minLines: 1,
      maxLines: 1,
      maxLength: 50,
      hint: widget.hint,
      controller: widget.controller,
      contentPadding: EdgeInsetsGeometry.zero,
      borderColor: app.colors.neutral.grey3,
      onChange: _onSearchChanged,
      height: 42,
      prefix: Padding(
        padding: const EdgeInsets.all(8.0),
        child: app.assets.icons.general.search.build(
          color: app.colors.neutral.grey3,
        ),
      ),
      suffix: widget.extraSuffix == null
          ? buildNativeSuffix()
          : Row(
              children: [
                buildNativeSuffix(),

                app.dimensions.padding.xs.gap(),
                VerticalDivider(
                  color: app.colors.neutral.grey3,
                  indent: 8.0,
                  endIndent: 8.0,
                ),
                app.dimensions.padding.xs.gap(),

                widget.extraSuffix!,
              ],
            ),
      borderRadius: widget.borderRadius ?? app.dimensions.border.borderRadius.s,
    );
  }
}

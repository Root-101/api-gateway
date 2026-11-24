import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

///label + 48 px field + error line, the form field of every dialog
class AppField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final String? errorText;
  final bool hasError;
  final String? hint;
  final bool mono;
  final bool obscure;
  final bool readOnly;
  final bool autofocus;
  final Widget? suffix;
  final Color? fill;
  final String? autofillHint;
  final int? maxLength;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AppField({
    required this.label,
    required this.controller,
    this.required = false,
    this.errorText,
    this.hasError = false,
    this.hint,
    this.mono = false,
    this.obscure = false,
    this.readOnly = false,
    this.autofocus = false,
    this.suffix,
    this.fill,
    this.autofillHint,
    this.maxLength,
    this.formatters,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final failed = hasError || errorText != null;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    final textStyle = mono
        ? monoStyle(size: 14, color: readOnly ? c.textSecondary : c.text)
        : TextStyle(fontSize: 15, color: c.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label, required: required),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            obscureText: obscure,
            readOnly: readOnly,
            style: textStyle,
            cursorColor: c.lilac,
            autofillHints: autofillHint == null ? null : [autofillHint!],
            inputFormatters: [
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
              ...?formatters,
            ],
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: textStyle.copyWith(color: c.textTertiary),
              filled: true,
              fillColor: fill ?? c.field,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: border(failed ? c.danger : c.outline),
              focusedBorder: border(c.lilac, 2),
              suffixIcon: suffix,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: c.dangerText,
            ),
          ),
        ],
      ],
    );
  }
}

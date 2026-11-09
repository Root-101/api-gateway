import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextInput extends StatefulWidget {
  static AppTextInput textField({
    required TextEditingController controller,
    String? hint,
    String? label,
    FormFieldValidator<String>? validator,
    TextCapitalization? textCapitalization,
    String? errorText,
    int? maxLength,
    TextInputType? keyboardType,
    int? minLines,
    int? maxLines,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChange,
    Widget? suffix,
    Widget? prefix,
    BorderRadiusGeometry? borderRadius,
    double? height,
    EdgeInsetsGeometry? contentPadding,
    Color? borderColor,
  }) {
    return AppTextInput(
      controller: controller,
      hint: hint,
      label: label,
      validator: validator,
      textCapitalization: textCapitalization,
      errorText: errorText,
      maxLength: maxLength,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      inputFormatters: inputFormatters,
      onChange: onChange,
      suffix: suffix,
      prefix: prefix,
      borderRadius: borderRadius,
      height: height,
      contentPadding: contentPadding,
      borderColor: borderColor,
    );
  }

  static AppTextInput passwordField({
    required TextEditingController controller,
    String? hint,
    String? label,
    FormFieldValidator<String>? validator,
    TextCapitalization? textCapitalization,
    String? errorText,
    int? maxLength,
    double? height,
  }) {
    return AppTextInput(
      controller: controller,
      hint: hint,
      obscureText: true,
      validator: validator,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      label: label,
      maxLines: 1,
      errorText: errorText,
      height: height,
    );
  }

  final TextEditingController controller;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final String? label;
  final String? hint;
  final int? minLines;
  final int? maxLines;
  final String? errorText;
  final TextCapitalization? textCapitalization;
  final ValueChanged<String>? onChange;
  final Widget? suffix;
  final Widget? prefix;
  final double? height;
  final EdgeInsetsGeometry? contentPadding;
  final Color? borderColor;

  //ui related input
  final Color? hintColor;

  final BorderRadiusGeometry? borderRadius;

  //password related
  final bool? obscureText;

  const AppTextInput({
    required this.controller,
    this.maxLength,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
    this.label,
    this.hint,
    this.minLines,
    this.maxLines,
    this.errorText,
    this.textCapitalization,
    this.onChange,
    this.suffix,
    this.prefix,
    this.height,
    //ui
    this.hintColor,
    this.borderRadius,
    this.contentPadding,
    this.borderColor,
    //password related
    this.obscureText,
    super.key,
  });

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  bool _hidePassword = true;

  String? internalErrorText;
  String? parentErrorText;

  @override
  void initState() {
    super.initState();
    parentErrorText = widget.errorText;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle hintTextStyle = app.textTheme.bodyMedium!.copyWith(
      color: widget.hintColor ?? app.colors.neutral.grey3,
    );

    TextCapitalization safeTextCapitalization =
        widget.textCapitalization ?? TextCapitalization.sentences;

    bool safeObscureText = widget.obscureText ?? false;

    String? finalErrorText = widget.errorText ?? internalErrorText;

    Widget? suffix =
        widget.suffix ??
        (safeObscureText
            ? IconButton(
                icon: Icon(
                  _hidePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
              )
            : null);
    return FormComponentTemplate(
      borderColor: widget.borderColor,
      suffix: suffix,
      prefix: widget.prefix,
      height: widget.height ?? 50,
      label: widget.label,
      errorText: finalErrorText,
      borderRadius: widget.borderRadius,
      child: TextFormField(
        onChanged: widget.onChange,
        textCapitalization: safeTextCapitalization,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        validator: (value) {
          parentErrorText = null;
          internalErrorText = null;
          if (widget.validator != null) {
            String? response = widget.validator!(value);
            if (response != null) {
              internalErrorText = response;
            }
          }
          setState(() {});
          return internalErrorText;
        },
        controller: widget.controller,
        maxLines: safeObscureText ? 1 : widget.maxLines,
        minLines: safeObscureText ? 1 : widget.minLines,
        obscureText: safeObscureText && _hidePassword,
        style: app.textTheme.bodyLarge?.copyWith(
          color: app.colors.neutral.white,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: widget.contentPadding,
          hoverColor: Colors.transparent,
          filled: true,
          fillColor: app.colors.neutral.transparent,
          hintText: widget.hint,
          hintStyle: hintTextStyle,
          counterText: '',
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}

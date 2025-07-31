import 'package:flutter/material.dart';
import '../config/theme/auth_theme.dart';
import '../constants/app_constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool isReadOnly;
  final int? maxLines;
  final TextStyle? hintStyle;
  final InputDecoration? inputDecoration;
  final TextInputType? keyboardType;
  final Function(String)? onchanged;
  final Function(String)? onSubmit;

  final String? Function(String?)? validator;

  final int? maxLength;

  final bool enabled;

  final bool isDateField;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.isReadOnly = false,
    this.validator,
    this.maxLines,
    this.onchanged,
    this.inputDecoration,
    this.onSubmit,
    this.hintStyle,
    this.maxLength,
    this.enabled = true,
    this.isDateField = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final decoration =
        (inputDecoration ?? AuthTheme.textFieldDecoration(label)).copyWith(
      hintText: hint,
      hintStyle: hintStyle,
    );

    // Force read-only for date fields when global setting is enabled
    final shouldBeReadOnly =
        isReadOnly || (isDateField && AppConstants.disableDateManualEntry);

    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      style: TextStyle(fontSize: 16),
      readOnly: shouldBeReadOnly,
      enabled: enabled,
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      onFieldSubmitted: onSubmit,
      onChanged: onchanged,
      decoration: decoration,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
    );
  }
}



class CustomTextField1 extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool isReadOnly;
  final int? maxLines;
  final TextStyle? hintStyle;
  final InputDecoration? inputDecoration;
  final TextInputType? keyboardType;
  final Function(String)? onchanged;
  final Function(String)? onSubmit;

  final String? Function(String?)? validator;

  final int? maxLength;

  final bool enabled;

  final bool isDateField;

  const CustomTextField1({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.isReadOnly = false,
    this.validator,
    this.maxLines,
    this.onchanged,
    this.inputDecoration,
    this.onSubmit,
    this.hintStyle,
    this.maxLength,
    this.enabled = true,
    this.isDateField = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final decoration =
        (inputDecoration ?? AuthTheme.textFieldDecoration(label)).copyWith(
      hintText: hint,
      hintStyle: hintStyle,
    );

    // Force read-only for date fields when global setting is enabled
    final shouldBeReadOnly =
        isReadOnly || (isDateField && AppConstants.disableDateManualEntry);

    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      style: TextStyle(fontSize: 16),
      readOnly: shouldBeReadOnly,
      enabled: enabled,
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      onFieldSubmitted: onSubmit,
      onChanged: onchanged,
      decoration: decoration,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
    );
  }
}

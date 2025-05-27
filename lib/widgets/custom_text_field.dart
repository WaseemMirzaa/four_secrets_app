import 'package:flutter/material.dart';
import '../config/theme/auth_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool isReadOnly;
  final int? maxLines;
  final TextInputType? keyboardType;

  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.isReadOnly = false,
    this.validator, this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines:  maxLines ?? 1,
      readOnly: isReadOnly,
      onTapOutside: (event) {
        FocusScope.of(context).unfocus();
      },
      decoration: AuthTheme.textFieldDecoration(label),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

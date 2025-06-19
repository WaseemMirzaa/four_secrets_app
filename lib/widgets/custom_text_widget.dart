import 'package:flutter/material.dart';

class CustomTextWidget extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextDecoration? decoration;

  const CustomTextWidget(
      {super.key,
      required this.text,
      this.fontSize,
      this.fontWeight,
      this.color,
      this.textAlign,
      this.decoration});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: textAlign ?? TextAlign.left,
        style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: fontWeight ?? FontWeight.normal,
            color: color ?? Colors.black,
            decoration: decoration));
  }
}

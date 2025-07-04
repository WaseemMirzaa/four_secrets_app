import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  final Color? textColor;

  const MyButton(
      {super.key,
      required this.onPressed,
      required this.text,
      this.color,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: color ?? Colors.white,
      disabledColor: Colors.grey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: onPressed == null
          ? Center(
              child: SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Text(
              text,
              style: TextStyle(
                color: textColor ?? Color.fromARGB(255, 107, 69, 106),
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

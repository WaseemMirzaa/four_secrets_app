import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? color;

  const MyButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color,
  });

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
      child: Text(
        text,
        style: TextStyle(
          color: onPressed == null 
              ? Colors.white.withOpacity(0.7) 
              : Color.fromARGB(255, 107, 69, 106),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

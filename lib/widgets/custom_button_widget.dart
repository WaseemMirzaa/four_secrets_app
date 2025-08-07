import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomButtonWidget extends StatefulWidget {
  final Function()? onPressed;
  final String text;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final double? width;
  final double? height;

  const CustomButtonWidget(
      {super.key,
      this.onPressed,
      required this.text,
      this.color,
      this.textColor,
      this.isLoading = false,
      this.width,
      this.height});

  @override
  State<CustomButtonWidget> createState() => _CustomButtonWidgetState();
}

class _CustomButtonWidgetState extends State<CustomButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        height: 40,
        width: widget.width ?? 180,
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        decoration: BoxDecoration(
            color: widget.color ?? Color.fromARGB(255, 107, 69, 106),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ]),
        child: widget.isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: Center(
                  child: CupertinoActivityIndicator(
                    color: Colors.white,
                  ),
                ),
              )
            : Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          widget.textColor ?? Color.fromARGB(255, 107, 69, 106),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

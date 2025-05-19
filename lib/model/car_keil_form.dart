import 'dart:math';
import 'package:flutter/material.dart';

class KeilForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: KeilPainter(),
      ),
    );
  }
}

class KeilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Color.fromARGB(255, 107, 69, 106)
      ..style = PaintingStyle.fill;

    final double centerX = size.width / 18.5;
    final double centerY = size.height / 2.9;
    final double radius = size.width / 4.9;

    final double angle =
        atan(5 / (radius - 5)); // Winkel für eine Breite von etwa 5 Pixel

    final Path path = Path()
      ..moveTo(centerX, centerY)
      ..lineTo(centerX + radius * cos(angle), centerY + radius * sin(angle))
      ..lineTo(centerX + (radius - 5) * cos(angle),
          centerY + (radius - 5) * sin(angle))
      ..lineTo(centerX + (radius - 5) * cos(-angle),
          centerY + (radius - 5) * sin(-angle))
      ..lineTo(centerX + radius * cos(-angle), centerY + radius * sin(-angle))
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

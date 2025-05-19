
import 'package:flutter/material.dart';

double gcSpacer = 4;

class SpacerWidget extends StatelessWidget {
  const SpacerWidget({super.key, required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: gcSpacer * height,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Color? confirmColor;
  final Color? cancelColor;
  final Color? confirmTextColor;
  final Color? cancelTextColor;
  final bool isLoading;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    required this.onCancel,
    this.confirmColor,
    this.cancelColor,
    this.confirmTextColor,
    this.cancelTextColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white,
      title: Center(
        child: CustomTextWidget(
          text: title,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 107, 69, 106),
        ),
      ),
      content: CustomTextWidget(
        text: message,
        fontSize: 15,
        textAlign: TextAlign.center,
        fontWeight: FontWeight.normal,
        color: Colors.black,
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        Row(
          children: [
            Expanded(
              child: CustomButtonWidget(
                text: cancelText,
                color: cancelColor ?? Colors.white,
                textColor: cancelTextColor ?? Colors.black,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButtonWidget(
                text: confirmText,
                color: Colors.red.shade300,
                textColor: confirmTextColor ?? Colors.white,
                isLoading: isLoading,
                onPressed: isLoading ? null : onConfirm,
              ),
            ),
          ],
        ),
        SpacerWidget(height: 5),
      ],
    );
  }
}

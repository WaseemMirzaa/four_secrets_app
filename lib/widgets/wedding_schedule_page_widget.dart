import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

class WeddingSchedulePageWidget extends StatelessWidget {
  final TextEditingController titleController;
  final String? label;
  final String? text;
  final int? maxLines;
  final bool isReadOnly;
  final String? hint;

  const WeddingSchedulePageWidget(
      {super.key,
      required this.titleController,
      this.isReadOnly = false,
      this.label,
      this.maxLines,
      this.hint,
      this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          text: text ?? "Beschreibung",
          fontSize: 18,
        ),
        SpacerWidget(height: 2),
        CustomTextField(
          controller: titleController,
          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
          inputDecoration: InputDecoration(
              filled: true,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
              fillColor: Colors.grey.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              )),
          isReadOnly: isReadOnly,
          label: label ?? "",
          maxLines: maxLines ?? 1,
        ),
      ],
    );
  }
}

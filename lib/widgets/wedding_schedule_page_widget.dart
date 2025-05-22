import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

class WeddingSchedulePageWidget extends StatelessWidget {
  final TextEditingController titleController;
  final String? label;
  final String? text;
  final int? maxLines;



  const WeddingSchedulePageWidget({super.key, required this.titleController, this.label, this.maxLines, this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
           CustomTextWidget(text: text ?? "Beschreibung", fontSize: 14,),
                    SpacerWidget(height: 2),
                    CustomTextField(controller: titleController, label: label ?? "Beschreibung", maxLines: maxLines ?? 1, ),
      ],
    );
  }
}
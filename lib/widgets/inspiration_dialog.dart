import 'dart:io';

import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

class InspirationDialog extends StatefulWidget {
  final File? imageFile;
  final TextEditingController controller;
  final VoidCallback saveNewTask;
  final VoidCallback selectImage;
  final bool isLoading;
  const InspirationDialog(
      {super.key,
      this.imageFile,
      required this.controller,
      required this.saveNewTask,
      required this.selectImage,
      required this.isLoading});

  @override
  State<InspirationDialog> createState() => _InspirationDialogState();
}

class _InspirationDialogState extends State<InspirationDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Textfield for adding new items

          SizedBox(
            height: 260,
            width: double.maxFinite,
            child: widget.imageFile != null
                ? Image.file(
                    widget.imageFile!,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    "assets/images/background/noimage.png",
                    fit: BoxFit.fill,
                  ),
          ),
          SpacerWidget(height: 2),

          MyButton(onPressed: widget.selectImage, text: "Bild auswählen"),

          SpacerWidget(height: 3),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: "Bildtitel eingeben",
                fillColor: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
          // Buttons row
          SpacerWidget(height: 2),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // save button
              widget.isLoading
                  ? Container(
                      width: 100,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 107, 69, 106),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    )
                  : MyButton(onPressed: widget.saveNewTask, text: "Speichern"),
              const SizedBox(
                width: 35,
              ),
              // cancel button
              MyButton(
                onPressed:
                    widget.isLoading ? null : () => Navigator.of(context).pop(),
                text: "Stornieren",
                color: widget.isLoading ? Colors.grey : null,
              ),
            ],
          ),
          SpacerWidget(height: 2),
        ],
      ),
    );
  }
}

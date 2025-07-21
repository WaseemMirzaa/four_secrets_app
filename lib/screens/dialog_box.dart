import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';

// ignore: must_be_immutable
class DialogBox extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final controller;
  VoidCallback onSave;
  VoidCallback onCancel;
  final bool isToDo;
  final bool isGuest;
  final bool isBudget;

  DialogBox({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.isToDo,
    required this.isGuest,
    required this.isBudget,
  });

  @override
  Widget build(BuildContext context) {
    // create an alert Box
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 170,
          color: Colors.grey.shade100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: "",
                    fillColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              // inside there are 2 Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // save - button
                  MyButton(onPressed: onSave, text: "Speichern"),
                  const SizedBox(
                    width: 35,
                  ),
                  // cancel button
                  MyButton(onPressed: onCancel, text: "Abbrechen"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: _getHintText(),
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                    filled: true,
                  ),
                ),
              ),
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  MyButton(
                    onPressed: onCancel,
                    text: "Abbrechen",
                  ),

                  const SizedBox(width: 35),

                  // Save button with custom styling
                  MyButton(
                    onPressed: onSave,
                    text: "Speichern",
                    textColor: Colors.white,
                    color: const Color.fromARGB(255, 107, 69, 106),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns appropriate hint text based on dialog type
  String _getHintText() {
    if (isToDo) {
      return "Neue Aufgabe eingeben...";
    } else if (isGuest) {
      return "Gast hinzufügen...";
    } else if (isBudget) {
      return "Budget-Eintrag...";
    } else {
      return "Eingabe...";
    }
  }
}
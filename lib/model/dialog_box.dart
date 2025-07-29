import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';

// ignore: must_be_immutable
class DialogBox extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isToDo;
  final bool isGuest;
  final bool isLoading;
  final bool isBudget;

  DialogBox({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.isToDo,
    required this.isGuest,
    this.isLoading = false,
    this.isBudget = false,
  });

  @override
  Widget build(BuildContext context) {
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
              // Textfield for adding new items
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
                  enabled: !isLoading, // Disable text field when loading
                ),
              ),

              // Buttons row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel Button
                    Expanded(
                      child: CustomButtonWidget(
                        text: "Abbrechen",
                        color: Colors.white,
                        textColor: Colors.black,
                        onPressed: isLoading ? null : onCancel,
                        isLoading: !isLoading,
                      ),
                    ),

                    const SizedBox(width: 25),

                    // Save Button
                    Expanded(
                      child: CustomButtonWidget(
                        text: "Speichern",
                        color: const Color.fromARGB(255, 107, 69, 106),
                        textColor: Colors.white,
                        onPressed: onSave,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns appropriate hint text based on dialog type
  String _getHintText() {
    if (isGuest && !isToDo) {
      return "Neuen Gast hinzufügen";
    } else if (isToDo && !isGuest) {
      return "Neue Aufgabe hinzufügen";
    } else if (isBudget) {
      return "Budget-Eintrag hinzufügen";
    } else {
      return "Neuen Eintrag hinzufügen";
    }
  }
}

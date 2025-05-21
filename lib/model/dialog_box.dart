import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';
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

  DialogBox({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.isToDo,
    required this.isGuest,
    this.isLoading = false,
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
              // Textfield for adding new items
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: (this.isGuest && !this.isToDo)
                        ? "Neuen Gast hinzufügen"
                        : "Neue Aufgabe hinzufügen",
                    fillColor: Color.fromARGB(255, 255, 255, 255),
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
                
                      Expanded(child: CustomButtonWidget(text: "Speichern", isLoading: isLoading, textColor: Colors.white, color: Color.fromARGB(255, 107, 69, 106), onPressed: onSave,)),
            
                    const SizedBox(
                      width: 25,
                    ),
                    // cancel button
              
                    Expanded(child: CustomButtonWidget(text: "Stornieren",  color: Colors.white, textColor: Colors.black, onPressed: onCancel,)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

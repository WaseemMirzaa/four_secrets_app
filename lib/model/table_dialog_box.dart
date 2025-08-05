import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';

// ignore: must_be_immutable
class TableDialogBox extends StatefulWidget {
  // Controllers for the form fields
  final TextEditingController nameController;
  final TextEditingController maxGuestsController;

  // Callback functions
  final VoidCallback onSave;
  final VoidCallback onCancel;

  // Table type selection
  String? selectedTableType;
  final Function(String) onTableTypeChanged;

  // List of available table types
  final List<String> tableTypes;

  // Loading state
  final bool isLoading;

  TableDialogBox({
    super.key,
    required this.nameController,
    required this.maxGuestsController,
    required this.onSave,
    required this.onCancel,
    required this.selectedTableType,
    required this.onTableTypeChanged,
    required this.tableTypes,
    this.isLoading = false,
  });

  @override
  State<TableDialogBox> createState() => _TableDialogBoxState();
}

class _TableDialogBoxState extends State<TableDialogBox> {
  @override
  Widget build(BuildContext context) {
    // create an alert Box
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 280, // Increased height to accommodate the dropdown
          color: Colors.grey.shade100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: widget.nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: "Tischnummer",
                    fillColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: widget.maxGuestsController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: "Wie viele Personen am Tisch?",
                    fillColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                    // color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: Color.fromARGB(255, 255, 255, 255),
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(8.0),
                      value: widget.selectedTableType,
                      hint: Text("Wählen Sie Tischform"),
                      items: widget.tableTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            widget.selectedTableType = newValue;
                          });
                          widget.onTableTypeChanged(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ),

              // Max guests field

              // Buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // save button
                  MyButton(
                    onPressed: widget.onCancel,
                    text: "Abbrechen",
                    color: Colors.white,
                  ),
                  const SizedBox(
                    width: 35,
                  ),
                  // cancel buttonk

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
                      : MyButton(
                          onPressed: widget.onSave,
                          color: Color.fromARGB(255, 107, 69, 106),
                          textColor: Colors.white,
                          text: "Speichern"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'custom_text_widget.dart';

class CollabTodoEditDialog extends StatefulWidget {
  final String initialName;
  final List<TextEditingController> itemControllers;
  final Future<void> Function(String, List<TextEditingController>) onSave;

  const CollabTodoEditDialog({
    Key? key,
    required this.initialName,
    required this.itemControllers,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CollabTodoEditDialog> createState() => _CollabTodoEditDialogState();
}

class _CollabTodoEditDialogState extends State<CollabTodoEditDialog> {
  late TextEditingController _editController;
  late List<TextEditingController> _itemControllers;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.initialName);
    _itemControllers = widget.itemControllers
        .map((c) => TextEditingController(text: c.text))
        .toList();
  }

  @override
  void dispose() {
    _editController.dispose();
    for (var c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white,
      title: Center(
        child: CustomTextWidget(
          text: 'Bearbeiten',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 107, 69, 106),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextWidget(
              text: 'Name ändern:',
              fontSize: 15,
              color: Colors.black,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _editController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                hintText: 'Name eingeben',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 107, 69, 106)),
                ),
              ),
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
            const SizedBox(height: 18),
            CustomTextWidget(
              text: 'Items:',
              fontSize: 15,
              color: Colors.black,
            ),
            const SizedBox(height: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_itemControllers.length, (idx) {
                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: TextField(
                          controller: _itemControllers[idx],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                            hintText: 'Item',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 107, 69, 106)),
                            ),
                          ),
                          style: TextStyle(color: Colors.black, fontSize: 15),
                        ),
                      ),
                    ),
                    if (_itemControllers.length > 1)
                      IconButton(
                        icon: Icon(FontAwesomeIcons.trashCan,
                            size: 18, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _itemControllers.removeAt(idx);
                          });
                        },
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(Icons.add, color: Color.fromARGB(255, 107, 69, 106)),
                label: CustomTextWidget(
                    text: 'Item hinzufügen',
                    color: Color.fromARGB(255, 107, 69, 106)),
                onPressed: () {
                  setState(() {
                    _itemControllers.add(TextEditingController());
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: CustomTextWidget(
                    text: 'Abbrechen',
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 107, 69, 106),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        try {
                          await widget.onSave(
                              _editController.text.trim(), _itemControllers);
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(false);
                          }
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : CustomTextWidget(
                        text: 'Speichern',
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

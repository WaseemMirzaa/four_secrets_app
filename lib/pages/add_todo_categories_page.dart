import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/category_model.dart';
import 'package:four_secrets_wedding_app/services/category_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';

class AddTodoCategoriesPage extends StatefulWidget {
  final CategoryModel? toDoModel;
  final String? id;

  const AddTodoCategoriesPage({Key? key, this.toDoModel, this.id})
      : super(key: key);

  @override
  State<AddTodoCategoriesPage> createState() => _AddTodoCategoriesPageState();
}

class _AddTodoCategoriesPageState extends State<AddTodoCategoriesPage> {
  final CategoryService categoryService = CategoryService();
  final TextEditingController _todoNameController = TextEditingController();
  List<TextEditingController> _itemControllerList = [TextEditingController()];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.toDoModel != null) {
      _todoNameController.text = widget.toDoModel!.categoryName;
      _itemControllerList = widget.toDoModel!.todos
          .map((e) => TextEditingController(text: e))
          .toList();
    }
  }

  void _addNewTextField() {
    setState(() {
      _itemControllerList.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: Text(
          widget.toDoModel != null
              ? 'Aufgabenliste bearbeiten'
              : 'Aufgabenliste hinzufügen',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              // Todo list name text field
              CustomTextField(
                controller: _todoNameController,
                label: 'Name der Aufgabenliste',
                inputDecoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Name der Aufgabenliste eingeben',
                  hintStyle:
                      TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        BorderSide(color: Colors.red.withValues(alpha: 0.7)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // List of editable text fields
              ..._itemControllerList.asMap().entries.map((entry) {
                int index = entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _itemControllerList[index],
                          label: "Unterpunkt ${index + 1}",
                          inputDecoration: InputDecoration(
                            hintText: "Unterpunkt eingeben ${index + 1}",
                            hintStyle: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.8)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.7)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.7)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.7)),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _itemControllerList.removeAt(index);
                          });
                        },
                        icon: Icon(Icons.delete, color: Colors.black),
                      ),
                    ],
                  ),
                );
              }),

              // Add new field button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: CustomButtonWidget(
                  width: double.infinity,
                  text: 'Hinzufügen',
                  textColor: Colors.white,
                  color: const Color.fromARGB(255, 148, 107, 147),
                  onPressed: _addNewTextField,
                ),
              ),

              const SizedBox(height: 20),

              // Cancel and Add/Update Category buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButtonWidget(
                      text: 'Abbrechen',
                      color: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomButtonWidget(
                      isLoading: _isLoading,
                      text: widget.toDoModel != null
                          ? 'Aktualisieren'
                          : 'Erstellen',
                      textColor: Colors.white,
                      color: const Color.fromARGB(255, 107, 69, 106),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        String categoryName = _todoNameController.text.trim();
                        if (categoryName.isEmpty) {
                          SnackBarHelper.showErrorSnackBar(context,
                              'Bitte geben Sie einen Namen für die Aufgabenliste ein');
                          setState(() {
                            _isLoading = false;
                          });
                          return;
                        }

                        // Filter out empty items
                        List<String> validItems = _itemControllerList
                            .map((controller) => controller.text.trim())
                            .where((text) => text.isNotEmpty)
                            .toList();

                        if (validItems.isEmpty) {
                          SnackBarHelper.showErrorSnackBar(context,
                              'Bitte fügen Sie mindestens eine Unterkategorie hinzu');
                          setState(() {
                            _isLoading = false;
                          });
                          return;
                        }

                        try {
                          if (widget.toDoModel != null) {
                            // Update existing category
                            await categoryService.updateCategory(
                              CategoryModel(
                                id: widget.toDoModel!.id,
                                categoryName: categoryName,
                                todos: validItems,
                                createdAt: widget.toDoModel!.createdAt,
                                userId: widget.toDoModel!.userId,
                              ),
                            );
                          } else {
                            // Add new category
                            await categoryService.createCategory(
                              categoryName,
                              validItems,
                            );
                          }

                          if (mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          if (mounted) {
                            SnackBarHelper.showErrorSnackBar(context,
                                'Fehler beim Speichern der Aufgabe: ${e.toString()}');
                          }
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _todoNameController.dispose();
    for (var controller in _itemControllerList) {
      controller.dispose();
    }
    super.dispose();
  }
}

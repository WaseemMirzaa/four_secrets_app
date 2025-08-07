import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      _itemControllerList.add(TextEditingController());
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
        foregroundColor: Colors.white,
        title: Text(
          widget.toDoModel != null
              ? 'Eigenen Listennamen bearbeiten'
              : 'Eigenen Listennamen hinzufügen',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Todo list name text field
            CustomTextField(
              controller: _todoNameController,
              label: 'Listennamen eingeben',
              inputDecoration: InputDecoration(
                fillColor: Colors.grey.withValues(alpha: 0.2),
                filled: true,
                hintText: 'Listennamen eingeben',
                hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onchanged: (_) => setState(() {}),
              maxLines: 1,
              keyboardType: TextInputType.text,
              maxLength: 50,
            ),
            const SizedBox(height: 10),

            // List of editable text fields
            ..._itemControllerList.asMap().entries.map((entry) {
              int index = entry.key;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: CustomTextField(
                  controller: _itemControllerList[index],
                  label: "Beschreibung ${index + 1}",
                  inputDecoration: InputDecoration(
                    hintText: "Beschreibung ${index + 1}",
                    fillColor: Colors.grey.withValues(alpha: 0.2),
                    filled: true,
                    hintStyle:
                        TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _itemControllerList.removeAt(index);
                        });
                      },
                      icon: Icon(
                        FontAwesomeIcons.trashCan,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _addNewTextField,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 107, 69, 106),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Hinzufügen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
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
                      text:
                          widget.toDoModel != null ? 'Speichern' : 'Speichern',
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

                        if (categoryName.length > 50) {
                          SnackBarHelper.showErrorSnackBar(context,
                              'Der Kategoriename darf maximal 50 Zeichen lang sein.');
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
                            Navigator.of(context).pop(true);
                          } else {
                            // Add new category
                            await categoryService.createCategory(
                              categoryName,
                              validItems,
                            );
                          }

                          // if (mounted) {
                          Navigator.of(context).pop(true);
                          // }
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

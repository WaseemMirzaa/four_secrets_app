import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/wedding_category_model.dart';
import 'package:four_secrets_wedding_app/services/wedidng_category_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';

class AddCustomCategoryWeddingSchedulePage extends StatefulWidget {
  final WeddingCategoryModel? weddingCategoryModel;
  final String? index;
  const AddCustomCategoryWeddingSchedulePage(
      {super.key, this.index, this.weddingCategoryModel});

  @override
  State<AddCustomCategoryWeddingSchedulePage> createState() =>
      _AddCustomCategoryWeddingSchedulePageState();
}

class _AddCustomCategoryWeddingSchedulePageState
    extends State<AddCustomCategoryWeddingSchedulePage> {
  final WeddingCategoryDatabase weddingCategoryDatabase =
      WeddingCategoryDatabase();
  final TextEditingController _categoryController = TextEditingController();
  List<TextEditingController> _itemControllerList = [TextEditingController()];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.weddingCategoryModel != null) {
      _categoryController.text = widget.weddingCategoryModel!.categoryName;
      _itemControllerList = widget.weddingCategoryModel!.items
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
        title: const Text(
          AppConstants.weddingCustomCategoryAppBarTitle,
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              // Category name text field
              CustomTextField(
                controller: _categoryController,
                label: AppConstants.weddingCategoryTitlePageItemName,
                inputDecoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: AppConstants.weddingCategoryTitlePageCategoryName,
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
                          label: "Item ${index + 1}",
                          inputDecoration: InputDecoration(
                            hintText: "Enter item ${index + 1}",
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
                      text: AppConstants.weddingCategoryTitlePageCancel,
                      color: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomButtonWidget(
                      isLoading: isLoading,
                      text: widget.weddingCategoryModel != null
                          ? AppConstants.weddingCategoryTitlePageUpdateCategory
                          : AppConstants.weddingCategoryTitlePageAddCategory,
                      textColor: Colors.white,
                      color: const Color.fromARGB(255, 107, 69, 106),
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });

                        String categoryName = _categoryController.text.trim();
                        if (categoryName.isEmpty) {
                          SnackBarHelper.showErrorSnackBar(
                              context,
                              AppConstants
                                  .weddingCategoryTitlePageAddCategoryError);
                          setState(() {
                            isLoading = false;
                          });
                          return;
                        }

                        // Filter out empty items
                        List<String> validItems = _itemControllerList
                            .map((controller) => controller.text.trim())
                            .where((text) => text.isNotEmpty)
                            .toList();

                        if (validItems.isEmpty) {
                          SnackBarHelper.showErrorSnackBar(
                              context,
                              AppConstants
                                  .weddingCategoryTitlePageAddItemError);
                          setState(() {
                            isLoading = false;
                          });
                          return;
                        }

                        try {
                          if (widget.weddingCategoryModel != null) {
                            // Update existing category
                            await weddingCategoryDatabase.updateCategory(
                              widget.index!,
                              categoryName,
                              validItems,
                            );
                          } else {
                            // Check if category already exists
                            final bool categoryAlreadyExists =
                                await weddingCategoryDatabase
                                    .categoryExists(categoryName);

                            if (categoryAlreadyExists) {
                              SnackBarHelper.showErrorSnackBar(context,
                                  "$categoryName existiert bereits. Bitte wähle einen anderen Namen");
                              setState(() {
                                isLoading = false;
                              });
                              return;
                            }

                            // Add new category
                            await weddingCategoryDatabase.addCategory(
                                categoryName, validItems);
                          }

                          if (mounted) {
                            Navigator.of(context).pop(weddingCategoryDatabase
                                .loadWeddingCategories());
                          }
                        } catch (e) {
                          if (mounted) {
                            SnackBarHelper.showErrorSnackBar(
                                context, "Error: ${e.toString()}");
                          }
                        } finally {
                          setState(() {
                            isLoading = false;
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
    _categoryController.dispose();
    for (var controller in _itemControllerList) {
      controller.dispose();
    }
    super.dispose();
  }
}

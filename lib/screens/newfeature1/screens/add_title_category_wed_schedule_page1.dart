import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_category_model1.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/wedidng_category_service1.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';

class AddCustomCategoryWeddingSchedulePage1 extends StatefulWidget {
  final WeddingCategoryModel1? weddingCategoryModel;
  final String? index;
  const AddCustomCategoryWeddingSchedulePage1(
      {super.key, this.index, this.weddingCategoryModel});

  @override
  State<AddCustomCategoryWeddingSchedulePage1> createState() =>
      _AddCustomCategoryWeddingSchedulePage1State();
}

class _AddCustomCategoryWeddingSchedulePage1State
    extends State<AddCustomCategoryWeddingSchedulePage1> {
  final WeddingCategoryDatabase1 weddingCategoryDatabase =
      WeddingCategoryDatabase1();
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
        title: const Text(
          "Benutzerdefinierte Kategorie hinzufügen1",
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category name text field
            CustomTextField(
              controller: _categoryController,
              label: AppConstants.weddingCategoryTitlePageItemName,
              inputDecoration: InputDecoration(
                fillColor: Colors.grey.withValues(alpha: 0.2),
                filled: true,
                hintText: AppConstants.weddingCategoryTitlePageCategoryName,
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
                  label: "Programmpunkt ${index + 1}",
                  inputDecoration: InputDecoration(
                    hintText: "Programmpunkt ${index + 1}",
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
                      CustomTextWidget(
                        text: 'Hinzufügen',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
                              'Bitte geben Sie einen Programmpunkt ein');
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

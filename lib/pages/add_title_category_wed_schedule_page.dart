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
  const AddCustomCategoryWeddingSchedulePage({super.key, this.index,  this.weddingCategoryModel});

  @override
  State<AddCustomCategoryWeddingSchedulePage> createState() => _AddCustomCategoryWeddingSchedulePageState();
}

class _AddCustomCategoryWeddingSchedulePageState extends State<AddCustomCategoryWeddingSchedulePage> {
  final WeddingCategoryDatabase weddingCategoryDatabase = WeddingCategoryDatabase();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final key = GlobalKey<FormState>();
  List<String> listOfitemInCategory = [];
  bool isUpdate = false;
  int updateIndex = -1; // Track which item is being updated
  String originalItemValue = ''; // Store original value for comparison

  @override
  void initState() {
    super.initState();
    if(widget.weddingCategoryModel != null){
      print(widget.index);
      _categoryController.text = widget.weddingCategoryModel!.categoryName;
      listOfitemInCategory = List.from(widget.weddingCategoryModel!.items); // Create a copy
    }
  }

  void _startEditingItem(String item, int index) {
    setState(() {
      _itemController.text = item;
      isUpdate = true;
      updateIndex = index;
      originalItemValue = item;
    });
  }

  void _cancelEdit() {
    setState(() {
      _itemController.clear();
      isUpdate = false;
      updateIndex = -1;
      originalItemValue = '';
    });
  }

  void _addOrUpdateItem() {
    String item = _itemController.text.trim();
    if (item.isEmpty) return;

    setState(() {
      if (isUpdate && updateIndex >= 0) {
        // Update existing item
        listOfitemInCategory[updateIndex] = item;
        // Reset update state
        isUpdate = false;
        updateIndex = -1;
        originalItemValue = '';
      } else {
        // Add new item (check for duplicates)
        if (!listOfitemInCategory.contains(item)) {
          listOfitemInCategory.add(item);
        } else {
          // Show error for duplicate
            SnackBarHelper.showErrorSnackBar(context, AppConstants.weddingCategoryDuplicateError);
          return;
        }
      }
      _itemController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(AppConstants.weddingCustomCategoryAppBarTitle, style: TextStyle(fontSize: 16),),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: key,
            child: Column(
              children: [
                // Category name text field
                CustomTextField(
                  controller: _categoryController,
                  label: AppConstants.weddingCategoryTitlePageItemName,
                  inputDecoration: InputDecoration(
                    hintText: AppConstants.weddingCategoryTitlePageCategoryName,
                    hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.7))
                    ), 
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.7))
                    ), 
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.7))
                    ), 
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.7))
                    ), 
                  ),
                ),
                const SizedBox(height: 10),
                
                // List of added items with edit and delete icons
                ...listOfitemInCategory.asMap().entries.map((entry) {
                  int index = entry.key;
                  String item = entry.value;
                  bool isCurrentlyEditing = isUpdate && updateIndex == index;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      spacing: 6,
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 17),
                            decoration: BoxDecoration(
                           
                              border: Border.all(
                                color: isCurrentlyEditing ? Color.fromARGB(255, 107, 69, 106) 
                                  : Colors.grey.withValues(alpha: 0.7), 
                                  width: isCurrentlyEditing ? 2 : 1
                              ), 
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Row(
                              children: [
                                Expanded(child: CustomTextWidget(text: item)),
                                if (isCurrentlyEditing)
                                  Icon(Icons.edit, color: Colors.black, size: 16),
                              ],
                            ),
                          ),
                        ),
                        // Edit button
                        IconButton(
                          onPressed: () => _startEditingItem(item, index),
                          icon: Icon(Icons.edit, color: Colors.black),
                        ),
                        // Delete button
                        IconButton(
                          onPressed: () {
                            setState(() {
                              listOfitemInCategory.removeAt(index);
                              // If we were editing this item, cancel the edit
                              if (isUpdate && updateIndex == index) {
                                _cancelEdit();
                              }
                            });
                          },
                          icon: Icon(Icons.delete, color: Colors.black),
                        )
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 10),
                
                // Row for adding/updating items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    children: [
                      Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _itemController,
                              label: isUpdate ? "Update Item" : AppConstants.weddingCategoryTitlePageItemName,
                              inputDecoration: InputDecoration(
                                hintText: isUpdate ? "Update item name" : AppConstants.weddingCategoryTitlePageItemName,
                                hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.7))
                                ), 
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.7))
                                ), 
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.7))
                                ), 
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.7))
                                ), 
                              ),
                            ),
                          ),
                          // Add/Update button
                          InkWell(
                            onTap: _addOrUpdateItem,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:  const Color.fromARGB(255, 107, 69, 106),
                              ),
                              child: Icon(
                                isUpdate ? FontAwesomeIcons.arrowsRotate : Icons.add, 
                                color: Colors.white
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Cancel button (only show when updating)
                      if (isUpdate) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          
                          child: TextButton(
                            
                            onPressed: _cancelEdit,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: 15
                              ),
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                                AppConstants.weddingCategoryTitlePageCancelEdit,
                              style: TextStyle(color: Color.fromARGB(255, 107, 69, 106), 
                              fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
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
                        text: widget.weddingCategoryModel != null 
                          ? AppConstants.weddingCategoryTitlePageUpdateCategory 
                          : AppConstants.weddingCategoryTitlePageAddCategory,
                        textColor: Colors.white,
                        
                        color: const Color.fromARGB(255, 107, 69, 106),
                        onPressed: () {
                          String categoryName = _categoryController.text.trim();
                          if (categoryName.isEmpty) {
                            SnackBarHelper.showErrorSnackBar(
                                context, AppConstants.weddingCategoryTitlePageAddCategoryError);
                            return;
                          }
                          if (listOfitemInCategory.isEmpty) {
                            SnackBarHelper.showErrorSnackBar(
                                context, AppConstants.weddingCategoryTitlePageAddItemError);
                            return;
                          }
                          
                          if(widget.weddingCategoryModel != null){
                            weddingCategoryDatabase.updateCategory(
                              widget.index!, 
                              categoryName, 
                              listOfitemInCategory
                            );
                          } else {
                            weddingCategoryDatabase.addCategory(
                              categoryName, 
                              listOfitemInCategory
                            );
                          }
                          Navigator.of(context).pop(weddingCategoryDatabase.loadWeddingCategories());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/services/wedidng_category_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

class WeddingCategoryTitlePage extends StatefulWidget {
  const WeddingCategoryTitlePage({super.key});

  @override
  State<WeddingCategoryTitlePage> createState() =>
      _WeddingCategoryTitlePageState();
}

class _WeddingCategoryTitlePageState extends State<WeddingCategoryTitlePage> {
  final TextEditingController _searchController = TextEditingController();
  final WeddingCategoryDatabase weddingCategoryDatabase = WeddingCategoryDatabase();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();

  bool isLoading = false;

  Map<String, List<String>> allCategories = {};
  Map<String, List<String>> filteredCategory = {};

  @override
  void initState() {
    super.initState();
    _loadAndInitCategories();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadAndInitCategories() async {
    setState(() {
      isLoading = true;
    });
    await weddingCategoryDatabase.createInitialWeddingCategories();
    await weddingCategoryDatabase.loadWeddingCategories();
    setState(() {
      allCategories = weddingCategoryDatabase.getCategoriesAsMap();
      filteredCategory = Map.from(allCategories);
      isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        filteredCategory = Map.from(allCategories);
      });
    } else {
      final Map<String, List<String>> newFiltered = {};
      allCategories.forEach((category, items) {
        final matchingItems = items
            .where((item) => item.toLowerCase().contains(query))
            .toList();
        if (matchingItems.isNotEmpty) {
          newFiltered[category] = matchingItems;
        }
      });
      setState(() {
        filteredCategory = newFiltered;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(AppConstants.weddingAddPageTitle),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Column(
          children: [
            CustomTextField(
              controller: _searchController,
               label: 'Search items...',
            ),
            const SpacerWidget(height: 4),
          Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  :  filteredCategory.isEmpty
                  ?  Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppConstants.weddingCategoryTitlePageNoCategoriesFound
                            ,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SpacerWidget(height: 5), 

                          CustomButtonWidget(text: AppConstants.weddingCategoryTitlePageAddCustomCategory, width: context.screenWidth, textColor: Colors.white, onPressed: () {
                             showDialog(context: context, builder: (_){
        return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: context.screenHeight * 0.3,
          color: Colors.grey.shade100,
          child: Column(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Textfield for adding new items
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: AppConstants.weddingCategoryTitlePageCategoryName,
                    fillColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: AppConstants.weddingCategoryTitlePageItemName,
                    fillColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(child: CustomButtonWidget(text: AppConstants.weddingCategoryTitlePageCancel, color: Colors.white,
                     onPressed: () {
                      _categoryController.clear();
                       _itemController.clear();
                       Navigator.of(context).pop();
                     },)),
                    const SizedBox(width: 20,),
                    Expanded(child: CustomButtonWidget(text: AppConstants.weddingCategoryTitlePageAddCategory, 
                    textColor: Colors.white,
                    color: Color.fromARGB(255, 107, 69, 106), onPressed: () {
                      if (_categoryController.text.isEmpty) {
                        SnackBarHelper.showErrorSnackBar(context, AppConstants.weddingCategoryTitlePageAddCategoryError);
                        return;
                      }
                      if (_itemController.text.isEmpty) {
                        SnackBarHelper.showErrorSnackBar(context, AppConstants.weddingCategoryTitlePageAddItemError);
                        return;
                      }
                      weddingCategoryDatabase.addCategory(_categoryController.text, [_itemController.text]);
                      _categoryController.clear();
                      _itemController.clear();
                      _loadAndInitCategories();
                      Navigator.of(context).pop();
                    },)),
                  ],
                ),
              )

            ],
          ),
        ),
      ),
    
    );
       });
                          },)
                          
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCategory.entries.length,
                      itemBuilder: (context, index) {
                        String categoryName = filteredCategory.entries.elementAt(index).key;
                        List<String> items = filteredCategory[categoryName]!;
                        
                        return  Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (_){
                weddingCategoryDatabase.deleteCategory(index);
                _loadAndInitCategories();
              },
              icon: Icons.delete,
              backgroundColor: Colors.red.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2), 
                            borderRadius: BorderRadius.circular(15)
                          ),
                          child: ExpansionTile(
                            
                            shape: OutlineInputBorder(
                              borderSide: BorderSide.none
                            ),
                            title: Text(
                              categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${items.length} items'),
                            children: items.map((item) {
                              return ListTile(
                                shape: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)
                                  
                                ),
                                title: Text("* $item"),
                                dense: true,
                                onTap: () {
                                  
                                  Navigator.of(context).pop(item);
                                },
                              );
                            }).toList(),
                           
                          ),
                          ),
                        );
                      },
                    )
          )
          ],
        ),
      ),
     
    );
  }
}

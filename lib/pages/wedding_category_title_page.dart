import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/wedding_category_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/wedidng_category_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
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
  final subCategoryController = TextEditingController();

  bool isLoading = false;

  Map<String, List<String>> allCategories = {};
  Map<String, List<String>> filteredCategory = {};
  List<WeddingCategoryModel> allCategoryModels = []; // Store full models

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
    final loadedCategories = await weddingCategoryDatabase.loadWeddingCategories();
    setState(() {
      // Get both the map and the full models
      allCategoryModels = loadedCategories;
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
        title: const Text(AppConstants.weddingCategorySelectCategory),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Column(
          children: [
            CustomTextField(
              controller: _searchController,
              label: 'suchen...',
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

                          CustomButtonWidget(text: AppConstants.weddingCategoryTitlePageAddCustomCategory,
                           width: context.screenWidth, textColor: Colors.white, onPressed: () async {

                              final emptyModel = WeddingCategoryModel(
                              id: "",
                              categoryName: '',
                              items: [],
                              createdAt: DateTime.now(),
                              userId: "", // or current user ID
                            );

                            var g =  Navigator.of(context).pushNamed(RouteManager.weddingCategoryCustomAddPage, 
                            arguments:  {
                              "weddingCategoryModel" : emptyModel,
                              "index" : ""
                            });
                           g.then((v){
                            _loadAndInitCategories();
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
                            childrenPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            title: Row(
                              spacing: 6,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      CustomTextWidget(text: '${items.length} Unterkategorie', fontWeight: FontWeight.w500,)
                                    ],
                                  ),
                                ),
                                 if (index > 4)
                          TextButton(onPressed: () async {
                             WeddingCategoryModel? model;
                            var id;
                            String? userId;
                            DateTime? createdAt;
                            // Option 1: Find by category name
                            model = allCategoryModels.firstWhere(
                              (m) {
                                id = m.id;
                                userId = m.userId;
                                createdAt = m.createdAt;
                                return m.categoryName == categoryName;
                              },
                              orElse: () => WeddingCategoryModel(
                                id: id, // or generate a new ID
                                categoryName: categoryName,
                                items: items,
                                createdAt: createdAt!,
                                userId: userId!, 
                              ),
                            );

   var updateCateData = await  showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, stateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          title:  ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:   Center(child: CustomTextWidget(text: "Unterkategorie hinzufügen", color: Color.fromARGB(255, 107, 69, 106), fontWeight: FontWeight.bold,)),

                ),
              ),
              titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
             
             

              
              SpacerWidget(height: 6),
              TextField(
                controller: subCategoryController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: "Titel",
                ),
              ),
              SpacerWidget(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                      Expanded(
                        child: CustomButtonWidget(
                          
                          text: AppConstants.weddingCategoryTitlePageAddCategory, isLoading: isLoading, textColor: Colors.white, onPressed: () async {
                              stateDialog(() => isLoading = true);
                              if (subCategoryController.text.isEmpty) {
                                SnackBarHelper.showErrorSnackBar(context, "Bitte geben Sie einen Titel für die Unterkategorie ein.");
                                stateDialog(() => isLoading = false);
                                return;
                              }
                              try {
                                 await weddingCategoryDatabase.updateCategory(
                                   model!.id,
                                  model.categoryName,
                                 model.items..add(subCategoryController.text)
                                );
                            var g =    await weddingCategoryDatabase.loadWeddingCategories();
        Navigator.of(context).pop(g);
                               subCategoryController.clear();
                              } catch (e) {
                                SnackBarHelper.showErrorSnackBar(context, "Fehler beim Hinzufügen der Unterkategorie");
                                stateDialog(() => isLoading = false);
                              }
                
                       
                            },
                            ),
                      ),
                                 
                  SizedBox(width: 24),
                  Expanded(child: CustomButtonWidget(text: "Abbrechen", 
                  color: Colors.white, onPressed: () => Navigator.of(context).pop(),)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

      if(updateCateData != null){
  final loadedCategories = await weddingCategoryDatabase.loadWeddingCategories();
  setState(() {
    // Update all the necessary state variables
    allCategoryModels = loadedCategories;
    allCategories = weddingCategoryDatabase.getCategoriesAsMap();
    filteredCategory = Map.from(allCategories);
    isLoading = false;
  });
  print("loadWeddingCategories completed");
} else {
  print("updateCateData is null");
}
                          }, child: Container(
                            padding: EdgeInsets.only(bottom:4 ),
                            decoration: BoxDecoration(
                              // border: Border(bottom: BorderSide(color: Colors.black))
                            ),
                            child: 
                             Icon(FontAwesomeIcons.plus, size: 20, color: Colors.black,), 
                            
                          )),

                            if (index > 4)
                          TextButton(onPressed: () {
                            // Find the corresponding model for this category
                            WeddingCategoryModel? model;
                            var id;
                            String? userId;
                            DateTime? createdAt;
                            // Option 1: Find by category name
                            model = allCategoryModels.firstWhere(
                              (m) {
                                id = m.id;
                                userId = m.userId;
                                createdAt = m.createdAt;
                                return m.categoryName == categoryName;
                              },
                              orElse: () => WeddingCategoryModel(
                                id: id, // or generate a new ID
                                categoryName: categoryName,
                                items: items,
                                createdAt: createdAt!,
                                userId: userId!, // You'll need to get this from somewhere
                              ),
                            );
                            
                            // Option 2: If you want to use the index to get the model
                            // (assuming the order matches)
                            // if (index < allCategoryModels.length) {
                            //   model = allCategoryModels[index];
                            // }
                            
                            var g = Navigator.of(context).pushNamed(
                              RouteManager.weddingCategoryCustomAddPage,
                              arguments: {
                                "weddingCategoryModel": model,
                                "index": id
                              },
                            );
                            g.then((v) {
                              _loadAndInitCategories();
                            });
                          }, child: Container(
                            padding: EdgeInsets.only(bottom:4 ),
                            decoration: BoxDecoration(
                              // border: Border(bottom: BorderSide(color: Colors.black))
                            ),
                            child: 
                             Icon(FontAwesomeIcons.penToSquare, size: 20, color: Colors.black,), 
                            
                          ))

                              ],
                            ), 
                            
                           
                            children: items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                         onTap: () {
                                            
                                            Navigator.of(context).pop(item);
                                          },
                                        child: Container(
                                            width: context.screenWidth,
                                           
                                            child: CustomTextWidget(text: "* $item", fontSize: 14,)
                                
                                         
                                        ),
                                      ),
                                    ),
                                            SizedBox( width: context.screenWidth/6,),
                                
                                  ],
                                ),
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
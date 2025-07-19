import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_category_model1.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/wedidng_category_service1.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

class WeddingCategoryTitlePage1 extends StatefulWidget {
  const WeddingCategoryTitlePage1({super.key});

  @override
  State<WeddingCategoryTitlePage1> createState() =>
      _WeddingCategoryTitlePage1State();
}

class _WeddingCategoryTitlePage1State extends State<WeddingCategoryTitlePage1> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController typeAheadController = TextEditingController();
  final WeddingCategoryDatabase1 weddingCategoryDatabase =
      WeddingCategoryDatabase1();
  final subCategoryController = TextEditingController();

  bool isLoading = false;
  bool isSearching = false;

  Map<String, List<String>> allCategories = {};
  Map<String, List<String>> filteredCategory = {};
  List<WeddingCategoryModel1> allCategoryModels = []; // Store full models

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
    final loadedCategories =
        await weddingCategoryDatabase.loadWeddingCategories();
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
        // Also search the category name as well as the items
        final categoryMatches = category.toLowerCase().contains(query);
        final matchingItems =
            items.where((item) => item.toLowerCase().contains(query)).toList();
        if (categoryMatches) {
          // If the category name matches, include all items
          newFiltered[category] = items;
        } else if (matchingItems.isNotEmpty) {
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
    typeAheadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Kategorie auswählen1"),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                RouteManager.addTitleCategoryWedSchedulePage1,
              );
            },
            icon: const Icon(FontAwesomeIcons.plus),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Suchen...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                // Categories list
                Expanded(
                  child: filteredCategory.isEmpty
                      ? const Center(
                          child: Text(
                            AppConstants.weddingCategoryTitlePageNoCategoriesFound,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCategory.length,
                          itemBuilder: (context, index) {
                            final categoryName = filteredCategory.keys.elementAt(index);
                            final items = filteredCategory[categoryName]!;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                title: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                children: items.map((item) {
                                  return ListTile(
                                    title: Text(item),
                                    onTap: () {
                                      Navigator.of(context).pop(item);
                                    },
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

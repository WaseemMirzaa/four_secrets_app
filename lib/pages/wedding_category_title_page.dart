import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/wedding_category_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/wedidng_category_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
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
  final TextEditingController typeAheadController = TextEditingController();
  final WeddingCategoryDatabase weddingCategoryDatabase =
      WeddingCategoryDatabase();
  var subCategoryController = TextEditingController();

  bool isLoading = false;
  bool isSearching = false;

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
        title: const Text(AppConstants.weddingCategorySelectCategory),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var g = await Navigator.of(context).pushNamed(
              RouteManager.weddingCategoryCustomAddPage,
              arguments: {"weddingCategoryModel": null, "index": ""});

          if (g != null) {
            _loadAndInitCategories();
          }
        },
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Column(
          children: [
            TypeAheadField<String>(
              controller: typeAheadController,
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) return [];
                setState(() => isSearching = true);
                await Future.delayed(const Duration(milliseconds: 150));
                final lower = pattern.toLowerCase();
                final Set<String> allSuggestions = {};
                allCategories.forEach((cat, items) {
                  if (cat.toLowerCase().contains(lower))
                    allSuggestions.add(cat);
                  allSuggestions.addAll(items
                      .where((item) => item.toLowerCase().contains(lower)));
                });
                if (mounted) setState(() => isSearching = false);
                return allSuggestions.toList();
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  onChanged: (value) {
                    setState(() {
                      controller.text = value;
                      isSearching = true;
                    });
                  },
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.grey.withValues(alpha: 0.8),
                    ),
                    hintText: "suchen...",
                    fillColor: Colors.grey.withValues(alpha: 0.2),
                    filled: true,
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                controller.clear();
                                _onSearchChanged();
                              });
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  ),
                );
              },
              itemBuilder: (context, suggestion) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      suggestion,
                      style: TextStyle(
                        color: Color.fromARGB(255, 107, 69, 106),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
              decorationBuilder: (context, child) => Material(
                type: MaterialType.card,
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
              onSelected: (suggestion) {
                setState(() {});
                _searchController.text = suggestion;
                typeAheadController.text = suggestion;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length),
                );
                typeAheadController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length),
                );
                _onSearchChanged();
                FocusScope.of(context).unfocus();
              },
              emptyBuilder: (context) {
                final text = typeAheadController.text.trim();
                if (text.isEmpty) {
                  return SizedBox.shrink();
                }
                if (isSearching) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return Container(
                    padding: EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () async {
                        var g = await Navigator.of(context).pushNamed(
                            RouteManager.weddingCategoryCustomAddPage,
                            arguments: {
                              "weddingCategoryModel": null,
                              "index": ""
                            });
                        if (g != null) {
                          _loadAndInitCategories();
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.plus,
                            size: 20,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Keine Ergebnisse gefunden",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                        ],
                      ),
                    ));
              },
            ),
            // const SpacerWidget(height: 4),
            Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _searchController.text.trim().isNotEmpty
                        ? SearchResultsListWidget(
                            filteredCategory: filteredCategory,
                            onItemTap: (item) {
                              Navigator.of(context).pop(item);
                            })
                        : filteredCategory.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppConstants
                                          .weddingCategoryTitlePageNoCategoriesFound,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SpacerWidget(height: 5),
                                    CustomButtonWidget(
                                      text: AppConstants
                                          .weddingCategoryTitlePageAddCustomCategory,
                                      width: context.screenWidth,
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        var g = Navigator.of(context).pushNamed(
                                            RouteManager
                                                .weddingCategoryCustomAddPage,
                                            arguments: {
                                              "weddingCategoryModel": null,
                                              "index": ""
                                            });
                                        g.then((v) {
                                          _loadAndInitCategories();
                                        });
                                      },
                                    )
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(bottom: 80),
                                itemCount: filteredCategory.entries.length,
                                itemBuilder: (context, index) {
                                  String categoryName = filteredCategory.entries
                                      .elementAt(index)
                                      .key;
                                  List<String> items =
                                      filteredCategory[categoryName]!;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Container(
                                      // color: Colors.blue,
                                      child: ExpansionTile(
                                        tilePadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
                                        backgroundColor:
                                            Colors.grey.withValues(alpha: 0.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        collapsedShape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        collapsedBackgroundColor:
                                            Colors.grey.withValues(alpha: 0.2),
                                        title: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  CustomTextWidget(
                                                    text: categoryName,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: CustomTextWidget(
                                                          text:
                                                              '${items.length} Unterkategorien',
                                                          fontSize: 14,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            onPressed:
                                                                () async {
                                                              WeddingCategoryModel?
                                                                  model;
                                                              var id;
                                                              String? userId;
                                                              DateTime?
                                                                  createdAt;
                                                              model =
                                                                  allCategoryModels
                                                                      .firstWhere(
                                                                (m) {
                                                                  id = m.id;
                                                                  userId =
                                                                      m.userId;
                                                                  createdAt = m
                                                                      .createdAt;
                                                                  return m.categoryName ==
                                                                      categoryName;
                                                                },
                                                                orElse: () =>
                                                                    WeddingCategoryModel(
                                                                  id: id,
                                                                  categoryName:
                                                                      categoryName,
                                                                  items: items,
                                                                  createdAt:
                                                                      createdAt!,
                                                                  userId:
                                                                      userId!,
                                                                ),
                                                              );

                                                              subCategoryController =
                                                                  TextEditingController();
                                                              var updateCateData =
                                                                  await showDialog(
                                                                context:
                                                                    context,
                                                                builder: (_) =>
                                                                    StatefulBuilder(
                                                                  builder: (_,
                                                                          stateDialog) =>
                                                                      AlertDialog(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                    titlePadding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    content:
                                                                        SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          SpacerWidget(
                                                                              height: 3),
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.all(0),
                                                                            child: Center(
                                                                                child: CustomTextWidget(
                                                                              text: "Unterkategorie hinzufügen",
                                                                              color: Color.fromARGB(255, 107, 69, 106),
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold,
                                                                            )),
                                                                          ),
                                                                          SpacerWidget(
                                                                              height: 8),
                                                                          TextField(
                                                                            controller:
                                                                                subCategoryController,
                                                                            decoration:
                                                                                InputDecoration(
                                                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                                              hintText: "Titel",
                                                                            ),
                                                                          ),
                                                                          SpacerWidget(
                                                                              height: 6),
                                                                          Row(
                                                                            spacing:
                                                                                12,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Expanded(
                                                                                child: Container(
                                                                                  constraints: BoxConstraints(
                                                                                    maxWidth: 160,
                                                                                  ),
                                                                                  child: CustomButtonWidget(
                                                                                    text: "Abbrechen",
                                                                                    color: Colors.white,
                                                                                    onPressed: () => Navigator.of(context).pop(),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Expanded(
                                                                                child: CustomButtonWidget(
                                                                                  text: AppConstants.weddingCategoryTitlePageAddCategory,
                                                                                  isLoading: isLoading,
                                                                                  textColor: Colors.white,
                                                                                  onPressed: () async {
                                                                                    stateDialog(() => isLoading = true);
                                                                                    if (subCategoryController.text.isEmpty) {
                                                                                      SnackBarHelper.showErrorSnackBar(context, "Bitte geben Sie einen Titel für die Unterkategorie ein.");
                                                                                      stateDialog(() => isLoading = false);
                                                                                      return;
                                                                                    }
                                                                                    try {
                                                                                      await weddingCategoryDatabase.updateCategory(model!.id, model.categoryName, model.items..add(subCategoryController.text));
                                                                                      var g = await weddingCategoryDatabase.loadWeddingCategories();
                                                                                      Navigator.of(context).pop(g);
                                                                                      subCategoryController.clear();
                                                                                      FocusScope.of(context).unfocus();
                                                                                    } catch (e) {
                                                                                      SnackBarHelper.showErrorSnackBar(context, "Fehler beim Hinzufügen der Unterkategorie");
                                                                                      stateDialog(() => isLoading = false);
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
                                                                ),
                                                              );

                                                              if (updateCateData !=
                                                                  null) {
                                                                final loadedCategories =
                                                                    await weddingCategoryDatabase
                                                                        .loadWeddingCategories();
                                                                setState(() {
                                                                  // Update all the necessary state variables
                                                                  allCategoryModels =
                                                                      loadedCategories;
                                                                  allCategories =
                                                                      weddingCategoryDatabase
                                                                          .getCategoriesAsMap();
                                                                  filteredCategory =
                                                                      Map.from(
                                                                          allCategories);
                                                                  isLoading =
                                                                      false;
                                                                });
                                                                print(
                                                                    "loadWeddingCategories completed");
                                                              } else {
                                                                print(
                                                                    "updateCateData is null");
                                                              }
                                                            },
                                                            icon: Icon(
                                                              FontAwesomeIcons
                                                                  .plus,
                                                              size: 20,
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      93,
                                                                      58,
                                                                      92),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            onPressed: () {
                                                              WeddingCategoryModel?
                                                                  model;
                                                              var id;
                                                              String? userId;
                                                              DateTime?
                                                                  createdAt;
                                                              model =
                                                                  allCategoryModels
                                                                      .firstWhere(
                                                                (m) {
                                                                  id = m.id;
                                                                  userId =
                                                                      m.userId;
                                                                  createdAt = m
                                                                      .createdAt;
                                                                  return m.categoryName ==
                                                                      categoryName;
                                                                },
                                                                orElse: () =>
                                                                    WeddingCategoryModel(
                                                                  id: id,
                                                                  categoryName:
                                                                      categoryName,
                                                                  items: items,
                                                                  createdAt:
                                                                      createdAt!,
                                                                  userId:
                                                                      userId!,
                                                                ),
                                                              );

                                                              var g = Navigator
                                                                      .of(context)
                                                                  .pushNamed(
                                                                RouteManager
                                                                    .weddingCategoryCustomAddPage,
                                                                arguments: {
                                                                  "weddingCategoryModel":
                                                                      model,
                                                                  "index": id
                                                                },
                                                              );
                                                              g.then((v) {
                                                                _loadAndInitCategories();
                                                              });
                                                            },
                                                            icon: Icon(
                                                              FontAwesomeIcons
                                                                  .penToSquare,
                                                              size: 20,
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      93,
                                                                      58,
                                                                      92),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            onPressed: () {
                                                              weddingCategoryDatabase
                                                                  .deleteCategory(
                                                                      index);
                                                              _loadAndInitCategories();
                                                            },
                                                            icon: Icon(
                                                              FontAwesomeIcons
                                                                  .trashCan,
                                                              size: 18,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          ...items.map((item) => Container(
                                                // color: Colors.purple,
                                                child: ListTile(
                                                  title: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: CustomTextWidget(
                                                      text: item,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    Navigator.of(context)
                                                        .pop(item);
                                                  },
                                                ),
                                              ))
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ))
          ],
        ),
      ),
    );
  }
}

class SearchResultsListWidget extends StatelessWidget {
  final Map<String, List<String>> filteredCategory;
  final void Function(String item)? onItemTap;
  const SearchResultsListWidget({
    Key? key,
    required this.filteredCategory,
    this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> results = [];
    filteredCategory.forEach((category, items) {
      if (items.isNotEmpty) {
        results.add(
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 107, 69, 106),
                        Color.fromARGB(255, 147, 109, 146),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextWidget(
                    text: category.toUpperCase(),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 107, 69, 106).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 107, 69, 106),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        for (int index = 0; index < items.length; index++) {
          final item = items[index];
          results.add(
            AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutBack,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 107, 69, 106).withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 8,
                    offset: Offset(0, -1),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onItemTap != null ? () => onItemTap!(item) : null,
                  borderRadius: BorderRadius.circular(16),
                  splashColor:
                      Color.fromARGB(255, 107, 69, 106).withValues(alpha: 0.1),
                  highlightColor:
                      Color.fromARGB(255, 107, 69, 106).withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomTextWidget(
                      text: item,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (filteredCategory.keys.toList().indexOf(category) <
            filteredCategory.keys.length - 1) {
          results.add(const SizedBox(height: 8));
        }
      }
    });
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.weddingCategoryTitlePageNoCategoriesFound,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const BouncingScrollPhysics(),
      children: results,
    );
  }
}

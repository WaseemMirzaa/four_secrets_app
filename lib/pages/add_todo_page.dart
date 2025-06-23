import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/category_model.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/category_service.dart';
import 'package:four_secrets_wedding_app/services/todo_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddTodoPage extends StatefulWidget {
  final ToDoModel? toDoModel;
  final String? id;
  const AddTodoPage({super.key, required this.toDoModel, required this.id});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final toDoService = TodoService();
  final categoryService = CategoryService();
  final _searchController = TextEditingController();
  final _categoryNameController = TextEditingController();
  bool isLoading = false;
  bool isSaving = false; // For Save button only
  bool isSearching = false;
  List<String> selectedItems = [];
  String? selectedCategory;

  Map<String, List<String>> allTodo = {};
  Map<String, List<String>> filteredTodo = {};
  List<CategoryModel> allTodoModels = []; // Store full models
  @override
  void initState() {
    super.initState();
    _loadAndInitCategories();

    // Handle incoming todo data if present
    if (widget.toDoModel != null) {
      setState(() {
        selectedCategory = widget.toDoModel!.toDoName;
        selectedItems = widget.toDoModel!.toDoItems
            .map((item) => item['name'] as String)
            .toList();
        _categoryNameController.text = widget.toDoModel!.toDoName;
      });
    }
  }

  Future<void> _loadAndInitCategories() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });
    try {
      await categoryService.createInitialCategories();
      print('🟢 Starting to load and initialize categories');
      final loadTodo = await categoryService.getCategories();
      print('🟢 Initial todo items created successfully');
      print('🟢 Todos loaded successfully: ${loadTodo.length} items');
      if (mounted) {
        setState(() {
          // Get both the map and the full models
          allTodoModels = loadTodo;

          allTodo = Map.fromEntries(
              loadTodo.map((todo) => MapEntry(todo.categoryName, todo.todos)));
          filteredTodo = Map.from(allTodo);
          isLoading = false;
        });
      }
    } catch (e) {
      print('🔴 Error in _loadAndInitCategories: $e');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, 'Fehler beim Laden der Kategorien: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged([String? query]) {
    final search = query ?? _searchController.text;
    if (search.isEmpty) {
      setState(() {
        filteredTodo = Map.from(allTodo);
      });
    } else {
      final Map<String, List<String>> newFiltered = {};
      final lowerQuery = search.toLowerCase();
      // Check for exact category match
      final exactCategory = allTodo.keys.firstWhere(
        (cat) => cat.toLowerCase() == lowerQuery,
        orElse: () => '',
      );
      if (exactCategory.isNotEmpty) {
        // Show all items in the matched category
        newFiltered[exactCategory] = allTodo[exactCategory]!;
      } else {
        // Otherwise, search for items
        allTodo.forEach((category, items) {
          final matchingItems = items
              .where((item) => item.toLowerCase().contains(lowerQuery))
              .toList();
          if (matchingItems.isNotEmpty) {
            newFiltered[category] = matchingItems;
          }
        });
      }
      setState(() {
        filteredTodo = newFiltered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          foregroundColor: Colors.white,
          title: const Text(AppConstants.toDoPageTitle),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var g = await Navigator.pushNamed(
                context, RouteManager.addTodoCategoriesPage,
                arguments: {
                  "toDoModel": null,
                  "id": null,
                });
            if (g == true) {
              print("🟢 g is true");
              _loadAndInitCategories();
              FocusScope.of(context).unfocus();
            }
          },
          child: Icon(Icons.add),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(children: [
            TypeAheadField<String>(
              controller: _searchController,
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) return [];
                setState(() => isSearching = true);
                await Future.delayed(const Duration(milliseconds: 150));
                final lower = pattern.toLowerCase();
                final Set<String> allSuggestions = {};
                allTodo.forEach((cat, items) {
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
                      _searchController.text = value;
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
                                isSearching = false;
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
                return suggestion.isNotEmpty
                    ? Container(
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
                      )
                    : SizedBox.shrink();
              },
              decorationBuilder: (context, child) => Material(
                type: MaterialType.card,
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
              onSelected: (suggestion) {
                setState(() {});
                _searchController.text = suggestion;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length),
                );
                _onSearchChanged(suggestion);
                FocusScope.of(context).unfocus();
              },
              emptyBuilder: (context) {
                final text = _searchController.text.trim();
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
                  child: Text(
                    "Keine Ergebnisse gefunden",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            const SpacerWidget(height: 4),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : _searchController.text.trim().isNotEmpty
                      ? _buildSearchResultsList()
                      : filteredTodo.isEmpty
                          ? Center(
                              child: CustomButtonWidget(
                                text: "hinzufügen",
                                textColor: Colors.white,
                                onPressed: () async {
                                  var g = await Navigator.pushNamed(context,
                                      RouteManager.addTodoCategoriesPage,
                                      arguments: {
                                        "toDoModel": null,
                                        "id": null,
                                      });
                                  if (g == true) {
                                    _loadAndInitCategories();
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: 80),
                              itemCount: filteredTodo.entries.length,
                              itemBuilder: (context, index) {
                                String toDoName =
                                    filteredTodo.entries.elementAt(index).key;
                                List<String> itemsToDo =
                                    filteredTodo[toDoName]!;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 16),
                                    shape: OutlineInputBorder(
                                        borderSide: BorderSide.none),
                                    childrenPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    initiallyExpanded: itemsToDo.any(
                                        (item) => selectedItems.contains(item)),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CustomTextWidget(
                                                text: toDoName,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              CustomTextWidget(
                                                text:
                                                    '${itemsToDo.length} Unterkategorie${itemsToDo.length != 1 ? 'n' : ''}',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (index > 5)
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                            tooltip: 'Löschen',
                                            onPressed: () async {
                                              try {
                                                final invitations =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'invitations')
                                                        .where('todoId',
                                                            isEqualTo:
                                                                allTodoModels[
                                                                        index]
                                                                    .id)
                                                        .get();
                                                for (var doc
                                                    in invitations.docs) {
                                                  await doc.reference.delete();
                                                }
                                                await categoryService
                                                    .deleteCategory(
                                                  allTodoModels[index].id,
                                                );
                                                _loadAndInitCategories();
                                              } catch (e) {
                                                if (mounted) {
                                                  SnackBarHelper.showErrorSnackBar(
                                                      context,
                                                      "Fehler beim Löschen: $e");
                                                }
                                              }
                                            },
                                          ),
                                        if (index > 5)
                                          IconButton(
                                            onPressed: () {
                                              CategoryModel? model =
                                                  allTodoModels.firstWhere(
                                                (m) =>
                                                    m.categoryName == toDoName,
                                                orElse: () => CategoryModel(
                                                  id: '',
                                                  categoryName: toDoName,
                                                  todos: itemsToDo,
                                                  createdAt: DateTime.now(),
                                                  userId: '',
                                                ),
                                              );
                                              var g = Navigator.of(context)
                                                  .pushNamed(
                                                RouteManager
                                                    .addTodoCategoriesPage,
                                                arguments: {
                                                  "toDoModel": model,
                                                  "id": model.id
                                                },
                                              );
                                              g.then((v) {
                                                _loadAndInitCategories();
                                              });
                                            },
                                            icon: Icon(
                                              FontAwesomeIcons.penToSquare,
                                              size: 20,
                                              color: Colors.black,
                                            ),
                                          ),
                                      ],
                                    ),
                                    children: itemsToDo.map((item) {
                                      final isSelected =
                                          selectedItems.contains(item);
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 20),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    if (isSelected) {
                                                      selectedItems
                                                          .remove(item);
                                                      if (selectedItems
                                                          .isEmpty) {
                                                        selectedCategory = null;
                                                      }
                                                    } else {
                                                      selectedItems.add(item);
                                                      selectedCategory =
                                                          toDoName;
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  width: context.screenWidth,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 20,
                                                        height: 20,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? Color.fromARGB(
                                                                  255,
                                                                  107,
                                                                  69,
                                                                  106)
                                                              : Colors.white,
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? Color
                                                                    .fromARGB(
                                                                        255,
                                                                        107,
                                                                        69,
                                                                        106)
                                                                : Colors.grey,
                                                            width: 2,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: isSelected
                                                            ? Icon(
                                                                Icons.check,
                                                                size: 16,
                                                                color: Colors
                                                                    .white,
                                                              )
                                                            : null,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: CustomTextWidget(
                                                          text: " $item",
                                                          fontSize: 14,
                                                          color: isSelected
                                                              ? Color.fromARGB(
                                                                  255,
                                                                  107,
                                                                  69,
                                                                  106)
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
            )
          ]),
        ),
        // At the bottom, add the Save button
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 60,
                width: context.screenWidth,
                child: CustomButtonWidget(
                  height: 60,
                  width: context.screenWidth,
                  text:
                      widget.toDoModel == null ? 'Speichern' : 'Aktualisieren',
                  textColor: Colors.white,
                  isLoading: isSaving,
                  onPressed: () async {
                    if (selectedItems.isEmpty) {
                      SnackBarHelper.showErrorSnackBar(context,
                          'Bitte wählen Sie mindestens ein Element aus');
                      return;
                    }
                    setState(() => isSaving = true);
                    try {
                      if (selectedCategory == null ||
                          selectedCategory!.isEmpty) {
                        // Category does not exist, so create it first
                        final newCategory =
                            await categoryService.createCategory(
                          (selectedCategory ?? '').trim(),
                          selectedItems,
                        );
                        selectedCategory = newCategory.categoryName;
                      }

                      // Now create the todo with the valid categoryId
                      await toDoService.createTodo(
                        (selectedCategory ?? '').trim(),
                        selectedItems,
                        '',
                      );
                      print("🟢 selectedCategory: $selectedCategory");
                      SnackBarHelper.showSuccessSnackBar(
                          context, 'Todo erfolgreich gespeichert');
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      print("🔴 Error: $e");

                      SnackBarHelper.showErrorSnackBar(
                          context, 'Fehler beim Speichern: $e');
                    } finally {
                      if (mounted) setState(() => isSaving = false);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    // Build a grouped list: category header, then matching items for that category
    final List<Widget> results = [];

    filteredTodo.forEach((category, items) {
      if (items.isNotEmpty) {
        // Enhanced Category Header
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

        // Enhanced Items List
        for (int index = 0; index < items.length; index++) {
          final item = items[index];
          final isSelected = selectedItems.contains(item);
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
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedItems.remove(item);
                      } else {
                        selectedItems.add(item);
                      }
                    });
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: selectedItems.contains(item),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedItems.add(item);
                              } else {
                                selectedItems.remove(item);
                              }
                            });
                          },
                          activeColor: Color.fromARGB(255, 107, 69, 106),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextWidget(
                            text: item,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: selectedItems.contains(item)
                                ? Color.fromARGB(255, 107, 69, 106)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Add spacing between categories
        if (filteredTodo.keys.toList().indexOf(category) <
            filteredTodo.keys.length - 1) {
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

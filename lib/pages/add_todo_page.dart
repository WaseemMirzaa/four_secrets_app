import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/category_model.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/category_service.dart';
import 'package:four_secrets_wedding_app/services/todo_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';

class AddTodoPage extends StatefulWidget {
  final ToDoModel? toDoModel;
  final String? id;
  final bool showOnlyCustomCategories;
  const AddTodoPage(
      {super.key,
      required this.toDoModel,
      required this.id,
      this.showOnlyCustomCategories = false});

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
  String? expandedCategory; // Only one expanded at a time
  Map<String, List<String>> selectedItemsByCategory =
      {}; // Multi-category selection
  Map<String, List<String>> allTodo = {};
  Map<String, List<String>> filteredTodo = {};
  List<CategoryModel> allTodoModels = []; // Store full models
  bool showFilteredList = false;
  DateTime? _selectedReminderDate;
  TimeOfDay? _selectedReminderTime;
  String? _selectedReminderDateText;
  String? _selectedReminderTimeText;
  bool _reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    print("🔵 ===== INIT STATE START =====");
    print("🔵 widget.toDoModel != null: ${widget.toDoModel != null}");
    print(
        "🔵 widget.showOnlyCustomCategories: ${widget.showOnlyCustomCategories}");

    // Handle incoming todo data if present
    if (widget.toDoModel != null) {
      print("🟢 widget.toDoModel: ${widget.toDoModel.toString()}");
      print("🟢 widget.toDoModel.categories: ${widget.toDoModel!.categories}");
      print("🟢 widget.toDoModel.toDoName: ${widget.toDoModel!.toDoName}");
      print("🟢 widget.toDoModel.toDoItems: ${widget.toDoModel!.toDoItems}");

      // Multi-category support for editing
      if (widget.toDoModel!.categories != null) {
        print("🟢 Processing multi-category data...");
        for (final cat in widget.toDoModel!.categories!) {
          print("🟢 Processing category: $cat");
          final catName = cat['categoryName'] as String;
          final itemsRaw = cat['items'] ?? [];
          print("🟢 Category name: $catName");
          print("🟢 Items raw: $itemsRaw");

          final items = (itemsRaw as List)
              .map((item) => item is String ? item : item['name'] as String)
              .toList();
          print("🟢 Items processed: $items");

          selectedItemsByCategory[catName] = List<String>.from(items);
          print(
              "🟢 Added to selectedItemsByCategory[$catName]: ${selectedItemsByCategory[catName]}");

          // Expand the first category by default
          expandedCategory ??= catName;
          print("🟢 Expanded category set to: $expandedCategory");
        }
      } else if (widget.toDoModel!.toDoName != null &&
          (widget.toDoModel!.toDoName ?? '').isNotEmpty) {
        print("🟢 Processing single-category data...");
        final catName = widget.toDoModel!.toDoName!;
        final items = widget.toDoModel!.toDoItems
                ?.map((item) => item['name'] as String)
                .toList() ??
            [];
        print("🟢 Single category name: $catName");
        print("🟢 Single category items: $items");

        selectedItemsByCategory[catName] = List<String>.from(items);
        expandedCategory = catName;
        print(
            "🟢 Single category added to selectedItemsByCategory[$catName]: ${selectedItemsByCategory[catName]}");
        print("🟢 Expanded category set to: $expandedCategory");
      }

      print("🟢 Final selectedItemsByCategory: $selectedItemsByCategory");
      print("🟢 Final expandedCategory: $expandedCategory");

      _categoryNameController.text = expandedCategory ?? '';
      print(
          "🟢 Category name controller text set to: ${_categoryNameController.text}");

      // Load reminder if present
      if (widget.toDoModel!.reminder != null &&
          widget.toDoModel!.reminder!.isNotEmpty) {
        print("🟢 Processing reminder: ${widget.toDoModel!.reminder}");
        final reminderDateTime = DateTime.tryParse(widget.toDoModel!.reminder!);
        if (reminderDateTime != null) {
          _reminderEnabled = true;
          _selectedReminderDate = reminderDateTime;
          _selectedReminderTime = TimeOfDay.fromDateTime(reminderDateTime);
          _selectedReminderDateText =
              "${reminderDateTime.day.toString().padLeft(2, '0')}/${reminderDateTime.month.toString().padLeft(2, '0')}/${reminderDateTime.year}";
          _selectedReminderTimeText =
              "${reminderDateTime.hour.toString().padLeft(2, '0')}:${reminderDateTime.minute.toString().padLeft(2, '0')} Uhr";
          print(
              "🟢 Reminder processed successfully: $_selectedReminderDateText $_selectedReminderTimeText");
        } else {
          print(
              "🔴 Failed to parse reminder datetime: ${widget.toDoModel!.reminder}");
        }
      } else {
        print("🟢 No reminder data found");
      }
    } else {
      print("🟢 No toDoModel provided - creating new todo");
    }

    print("🔵 ===== CALLING _loadAndInitCategories =====");
    // Load categories after setting up selected items
    _loadAndInitCategories();
  }

  Future<void> _loadAndInitCategories() async {
    print("🔵 ===== _loadAndInitCategories START =====");
    print("🔵 mounted: $mounted");

    if (!mounted) {
      print("🔴 Component not mounted, returning early");
      return;
    }

    setState(() {
      isLoading = true;
    });
    print("🔵 Set isLoading = true");

    try {
      print('🟢 Starting to load and initialize categories');
      await categoryService.createInitialCategories();
      print('🟢 Initial categories created');

      List<CategoryModel> loadTodo;

      // If editing a todo, load the specific category with ALL its items
      print("🔵 Checking editing conditions:");
      print("🔵 widget.toDoModel != null: ${widget.toDoModel != null}");
      print(
          "🔵 selectedItemsByCategory.isNotEmpty: ${selectedItemsByCategory.isNotEmpty}");
      print("🔵 selectedItemsByCategory: $selectedItemsByCategory");

      if (widget.toDoModel != null && selectedItemsByCategory.isNotEmpty) {
        print('🟢 ===== EDITING MODE ACTIVATED =====');
        print('🟢 Loading category with ALL items');
        final categoryName = selectedItemsByCategory.keys.first;
        print('🟢 Target category name: "$categoryName"');

        // Load both standard and custom categories to find the complete category
        print('🟢 Loading standard categories...');
        final standardCategories = await categoryService.getCategories();
        print(
            '🟢 Standard categories loaded: ${standardCategories.length} categories');
        for (var cat in standardCategories) {
          print(
              '🟢   - Standard: "${cat.categoryName}" (${cat.todos.length} items)');
        }

        print('🟢 Loading custom categories...');
        final customCategories = await categoryService.getCustomCategories(
            widget.toDoModel?.isShared ?? false, widget.toDoModel);
        print(
            '🟢 Custom categories loaded: ${customCategories.length} categories');
        for (var cat in customCategories) {
          print(
              '🟢   - Custom: "${cat.categoryName}" (${cat.todos.length} items)');
        }

        final allCategories = [...standardCategories, ...customCategories];
        print(
            '🟢 Combined categories: ${allCategories.length} total categories');

        // Find the specific category
        print('🟢 Searching for category: "$categoryName"');
        CategoryModel? specificCategory;
        try {
          specificCategory = allCategories.firstWhere(
            (cat) => cat.categoryName == categoryName,
          );
          print('🟢 ✅ Category FOUND: "${specificCategory.categoryName}"');
          print('🟢 Category ID: "${specificCategory.id}"');
          print('🟢 Category todos: ${specificCategory.todos}');
          print('🟢 Category todos length: ${specificCategory.todos.length}');
        } catch (e) {
          specificCategory = null;
          print('🔴 ❌ Category NOT FOUND: "$categoryName"');
          print('🔴 Error: $e');
        }

        if (specificCategory != null) {
          // Category found - use it with ALL its items
          loadTodo = [specificCategory];
          print('🟢 ✅ Using found category with ALL items');
          print(
              '🟢 Loaded category "${categoryName}" with ${specificCategory.todos.length} total items');
          print('🟢 Items: ${specificCategory.todos}');
        } else {
          // Category not found - create fallback with selected items
          print('🟡 ⚠️ Creating fallback category');
          final selectedItems = selectedItemsByCategory[categoryName] ?? [];
          print('🟡 Selected items for fallback: $selectedItems');

          final fallbackCategory = CategoryModel(
            id: '',
            categoryName: categoryName,
            todos: selectedItems,
            createdAt: DateTime.now(),
            userId: '',
          );
          loadTodo = [fallbackCategory];
          print(
              '🟡 Created fallback category "${categoryName}" with ${fallbackCategory.todos.length} items');
          print('🟡 Fallback items: ${fallbackCategory.todos}');
        }

        print('� ===== EDITING MODE RESULT =====');
        print('🟢 Final loadTodo length: ${loadTodo.length}');
        if (loadTodo.isNotEmpty) {
          print('🟢 Final category: "${loadTodo[0].categoryName}"');
          print('🟢 Final items count: ${loadTodo[0].todos.length}');
          print('🟢 Final items: ${loadTodo[0].todos}');
        }
      } else {
        // Load categories based on the showOnlyCustomCategories flag
        print('🔵 ===== NORMAL MODE ACTIVATED =====');
        print(
            '🔵 showOnlyCustomCategories: ${widget.showOnlyCustomCategories}');

        if (widget.showOnlyCustomCategories) {
          print('🔵 Loading custom categories only...');
          loadTodo = await categoryService.getCustomCategories(false);
        } else {
          print('🔵 Loading standard categories...');
          loadTodo = await categoryService.getCategories();
        }

        print('🔵 Loaded ${loadTodo.length} categories in normal mode');
        for (var cat in loadTodo) {
          print('🔵   - "${cat.categoryName}" (${cat.todos.length} items)');
        }
      }

      print('🟢 ===== FINAL PROCESSING =====');
      print('🟢 Initial todo items created successfully');
      print('🟢 Todos loaded successfully: ${loadTodo.length} items');

      // Log all loaded categories and their items
      for (var todo in loadTodo) {
        print(
            '🟢 Final category: "${todo.categoryName}" with ${todo.todos.length} items');
        print('🟢   Items: ${todo.todos}');
      }

      if (mounted) {
        print('🟢 Component still mounted, setting state...');
        setState(() {
          allTodoModels = loadTodo;
          allTodo = Map.fromEntries(
              loadTodo.map((todo) => MapEntry(todo.categoryName, todo.todos)));
          filteredTodo = Map.from(allTodo);
          isLoading = false;
        });

        print('🟢 State updated successfully');
        print('🟢 allTodoModels length: ${allTodoModels.length}');
        print('🟢 allTodo keys: ${allTodo.keys.toList()}');
        print('🟢 filteredTodo keys: ${filteredTodo.keys.toList()}');
        print('🟢 isLoading: $isLoading');

        // Log the final state for debugging
        allTodo.forEach((categoryName, items) {
          print(
              '🟢 Final allTodo["$categoryName"]: $items (${items.length} items)');
        });
      } else {
        print('🔴 Component not mounted, skipping state update');
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

  String _getAppBarTitle() {
    if (widget.toDoModel != null && selectedItemsByCategory.isNotEmpty) {
      // Editing mode - show the category name being edited
      final categoryName = selectedItemsByCategory.keys.first;
      return "Bearbeiten: $categoryName";
    } else if (widget.showOnlyCustomCategories) {
      return "Eigene To-Do Listen";
    } else {
      return AppConstants.toDoPageTitle;
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
        newFiltered[exactCategory] = allTodo[exactCategory]!;
      } else {
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
          foregroundColor: Colors.white,
          title: Text(_getAppBarTitle()),
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
                await Future.delayed(const Duration(milliseconds: 50));
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
                                filteredTodo = Map.from(allTodo);
                                isSearching = false;
                                showFilteredList = false;
                                expandedCategory = null;
                                selectedItemsByCategory.clear();
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
                          title: CustomTextWidget(
                            text: suggestion,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 107, 69, 106),
                          ),
                        ),
                      )
                    : SizedBox.shrink();
              },
              decorationBuilder: (context, child) => Material(
                type: MaterialType.card,
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
              onSelected: (suggestion) {
                setState(() {
                  showFilteredList = true;
                  // If suggestion is a category, set as activeCategory
                  if (allTodo.containsKey(suggestion)) {
                    expandedCategory = suggestion;
                  } else {
                    // Find which category this item belongs to
                    final found = allTodo.entries.firstWhere(
                        (e) => e.value.contains(suggestion),
                        orElse: () => MapEntry('', []));
                    if (found.key.isNotEmpty) {
                      expandedCategory = found.key;
                    }
                  }
                });
                _searchController.text = suggestion;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length),
                );
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () async {
                      final newCategoryName = _searchController.text.trim();
                      if (allTodo.containsKey(newCategoryName)) {
                        SnackBarHelper.showErrorSnackBar(
                            context, 'Kategorie existiert bereits!');
                        return;
                      }
                      var g = Navigator.of(context).pushNamed(
                          RouteManager.addTodoCategoriesPage,
                          arguments: {"toDoModel": null, "id": null});
                      if (g == true) {
                        _loadAndInitCategories();
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.plus,
                          size: 18,
                          color: Colors.black,
                        ),
                        SizedBox(width: 10),
                        CustomTextWidget(
                          text: "Keine Ergebnisse gefunden",
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SpacerWidget(height: 4),
            // Reminder Section

            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : (() {
                      if (filteredTodo.isEmpty) {
                        return Center(
                          child: CustomButtonWidget(
                            text: "hinzufügen",
                            textColor: Colors.white,
                            onPressed: () async {
                              final newCategoryName =
                                  _searchController.text.trim();
                              if (allTodo.containsKey(newCategoryName)) {
                                SnackBarHelper.showErrorSnackBar(
                                    context, 'Kategorie existiert bereits!');
                                return;
                              }
                              var g = await Navigator.pushNamed(
                                  context, RouteManager.addTodoCategoriesPage,
                                  arguments: {
                                    "toDoModel": null,
                                    "id": null,
                                  });
                              if (g == true) {
                                _loadAndInitCategories();
                              }
                            },
                          ),
                        );
                      }
                      // If editing, only show the category being edited
                      Map<String, List<String>> displayTodo = filteredTodo;
                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: 80),
                        itemCount: displayTodo.entries.length,
                        itemBuilder: (context, index) {
                          String toDoName =
                              displayTodo.entries.elementAt(index).key;
                          List<String> itemsToDo = displayTodo[toDoName]!;
                          final isExpanded = expandedCategory == toDoName;
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ExpansionTile(
                              key: PageStorageKey(toDoName),
                              tilePadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              shape: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                              childrenPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              initiallyExpanded:
                                  isExpanded || widget.toDoModel != null,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  if (expanded) {
                                    expandedCategory = toDoName;
                                    // Optionally, clear selection for other categories if you want only one category's subitems to be selected at a time:
                                    // selectedItemsByCategory.removeWhere((key, value) => key != toDoName);
                                  } else {
                                    expandedCategory = null;
                                  }
                                });
                              },
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
                                  if (widget.toDoModel == null) ...[
                                    IconButton(
                                      icon: Icon(
                                        FontAwesomeIcons.trashCan,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      tooltip: 'Löschen',
                                      onPressed: () async {
                                        var g = await showDialog(
                                            context: context,
                                            builder: (context) =>
                                                StatefulBuilder(
                                                    builder: (context, statee) {
                                                  return CustomDialog(
                                                      isLoading: isSaving,
                                                      title: "Löschen",
                                                      message:
                                                          "Möchten Sie diese Liste wirklich löschen?",
                                                      confirmText: "Löschen",
                                                      cancelText: "Abbrechen",
                                                      onConfirm: () async {
                                                        statee(() {
                                                          isSaving = true;
                                                        });
                                                        try {
                                                          // Find the category model to get the ID
                                                          CategoryModel?
                                                              categoryToDelete =
                                                              allTodoModels
                                                                  .firstWhere(
                                                            (m) =>
                                                                m.categoryName ==
                                                                toDoName,
                                                            orElse: () =>
                                                                CategoryModel(
                                                              id: '',
                                                              categoryName:
                                                                  toDoName,
                                                              todos: [],
                                                              createdAt:
                                                                  DateTime
                                                                      .now(),
                                                              userId: '',
                                                            ),
                                                          );

                                                          if (categoryToDelete
                                                              .id.isNotEmpty) {
                                                            // Actually delete from database
                                                            await categoryService
                                                                .deleteCategory(
                                                                    categoryToDelete
                                                                        .id);
                                                            SnackBarHelper
                                                                .showSuccessSnackBar(
                                                                    context,
                                                                    'Kategorie erfolgreich gelöscht');
                                                          }
                                                        } catch (e) {
                                                          print(
                                                              '🔴 Error deleting category: $e');
                                                          SnackBarHelper
                                                              .showErrorSnackBar(
                                                                  context,
                                                                  'Fehler beim Löschen: $e');
                                                        } finally {
                                                          statee(() {
                                                            isSaving = false;
                                                          });
                                                        }
                                                        Navigator.of(context)
                                                            .pop(true);
                                                      },
                                                      onCancel: () {
                                                        statee(() {
                                                          isSaving = false;
                                                        });
                                                        Navigator.of(context)
                                                            .pop();
                                                      });
                                                }));
                                        if (g == true) {
                                          _loadAndInitCategories();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        CategoryModel? model =
                                            allTodoModels.firstWhere(
                                          (m) => m.categoryName == toDoName,
                                          orElse: () => CategoryModel(
                                            id: '',
                                            categoryName: toDoName,
                                            todos: itemsToDo,
                                            createdAt: DateTime.now(),
                                            userId: '',
                                          ),
                                        );
                                        var g = Navigator.of(context).pushNamed(
                                          RouteManager.addTodoCategoriesPage,
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
                                        color: const Color.fromARGB(
                                            255, 107, 69, 106),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              children: itemsToDo.map((item) {
                                final isSelected =
                                    selectedItemsByCategory[toDoName]
                                            ?.contains(item) ??
                                        false;
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            print(
                                                '🔵 ===== ITEM SELECTION CLICKED =====');
                                            print('🔵 Category: "$toDoName"');
                                            print('🔵 Item: "$item"');
                                            print(
                                                '🔵 Current isSelected: $isSelected');
                                            print(
                                                '🔵 Current selectedItemsByCategory: $selectedItemsByCategory');

                                            if (toDoName.trim().isEmpty) {
                                              print(
                                                  '🔴 Category name is empty, showing error');
                                              SnackBarHelper.showErrorSnackBar(
                                                  context,
                                                  'Kategorie darf nicht leer sein!');
                                              return;
                                            }
                                            setState(() {
                                              print(
                                                  '🔵 Setting state for item selection...');
                                              // Only allow one category selection at a time, but multiple subitems in that category
                                              if (selectedItemsByCategory
                                                      .isEmpty ||
                                                  selectedItemsByCategory
                                                      .containsKey(toDoName)) {
                                                print(
                                                    '🟢 Same category or empty selection - toggling subitem');
                                                // Same category: just toggle subitem
                                                final items = List<String>.from(
                                                    selectedItemsByCategory[
                                                            toDoName] ??
                                                        <String>[]);
                                                print(
                                                    '🟢 Current items in category: $items');

                                                if (isSelected) {
                                                  print(
                                                      '🟢 Item was selected, removing: "$item"');
                                                  items.remove(item);
                                                } else {
                                                  print(
                                                      '🟢 Item was not selected, adding: "$item"');
                                                  items.add(item);
                                                }

                                                print(
                                                    '🟢 Items after toggle: $items');

                                                if (items.isEmpty) {
                                                  print(
                                                      '🟢 No items left, removing category from selection');
                                                  selectedItemsByCategory
                                                      .remove(toDoName);
                                                } else {
                                                  print(
                                                      '🟢 Updating category with items: $items');
                                                  selectedItemsByCategory[
                                                      toDoName] = items;
                                                }
                                              } else {
                                                print(
                                                    '🟡 Different category - clearing previous and starting new selection');
                                                print(
                                                    '🟡 Previous selectedItemsByCategory: $selectedItemsByCategory');
                                                // Different category: clear previous, start new selection
                                                selectedItemsByCategory.clear();
                                                selectedItemsByCategory[
                                                    toDoName] = [item];
                                                print(
                                                    '🟡 New selectedItemsByCategory: $selectedItemsByCategory');
                                              }

                                              print(
                                                  '🔵 Final selectedItemsByCategory: $selectedItemsByCategory');
                                            });
                                          },
                                          child: Container(
                                            width: context.screenWidth,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Color.fromARGB(
                                                            255, 107, 69, 106)
                                                        : Colors.white,
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? Color.fromARGB(
                                                              255, 107, 69, 106)
                                                          : Colors.grey,
                                                      width: 2,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: isSelected
                                                      ? Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Colors.white,
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
                                                            255, 107, 69, 106)
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
                      );
                    })(),
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
                    print('🔥🔥🔥 About to call createTodo, userId: ' +
                        (toDoService.userId ?? 'null'));
                    if (toDoService.userId == null ||
                        toDoService.userId!.isEmpty) {
                      throw Exception(
                          '🔥🔥🔥 FATAL: userId is null or empty in UI!');
                    }
                    // Remove any empty category keys before saving
                    selectedItemsByCategory
                        .removeWhere((k, v) => k.trim().isEmpty);
                    // Flatten all selected items for validation
                    final allSelected = selectedItemsByCategory.values
                        .expand((x) => x)
                        .toList();
                    if (allSelected.isEmpty) {
                      SnackBarHelper.showErrorSnackBar(context,
                          'Bitte wählen Sie mindestens ein Element aus');
                      return;
                    }
                    setState(() => isSaving = true);
                    try {
                      // Check for duplicate category name before creating (only for new todos)
                      final entry = selectedItemsByCategory.entries.first;
                      final categoryName = entry.key;

                      if (widget.toDoModel == null) {
                        final exists = await toDoService
                            .checkForDuplicateCategory(categoryName);

                        if (exists) {
                          print('🔴🔴🔴 Kategorie existiert bereits!');
                          SnackBarHelper.showErrorSnackBar(
                              context, 'Kategorie existiert bereits!');
                          setState(() => isSaving = false);
                          return;
                        }
                      }
                      final categories = [
                        {'categoryName': entry.key, 'items': entry.value}
                      ];
                      String? reminderIso;
                      if (_reminderEnabled &&
                          _selectedReminderDate != null &&
                          _selectedReminderTime != null) {
                        final reminderDateTime = DateTime(
                          _selectedReminderDate!.year,
                          _selectedReminderDate!.month,
                          _selectedReminderDate!.day,
                          _selectedReminderTime!.hour,
                          _selectedReminderTime!.minute,
                        );
                        reminderIso = reminderDateTime.toIso8601String();
                      }
                      if (widget.toDoModel != null) {
                        // EDITING EXISTING TODO
                        final updatedTodo = widget.toDoModel!.copyWith(
                          categories: categories,
                          reminder: reminderIso,
                        );
                        await toDoService.updateTodo(updatedTodo);
                        // Schedule local notification for owner
                        if (reminderIso != null) {
                          await NotificationService.scheduleAlarmNotification(
                            id: updatedTodo.id.hashCode,
                            dateTime: DateTime.parse(reminderIso),
                            title: updatedTodo.toDoName ?? categoryName,
                            body: 'Erinnerung für Ihre Aufgabe',
                            payload: updatedTodo.id,
                          );
                        }
                        SnackBarHelper.showSuccessSnackBar(
                            context, 'Todo erfolgreich aktualisiert');
                        Navigator.of(context).pop(true);
                      } else {
                        // CREATING NEW TODO
                        await toDoService.createTodo(
                          categories: categories,
                          reminder: reminderIso,
                        );
                        // Schedule local notification for owner
                        if (reminderIso != null) {
                          // Wait for Firestore to generate the ID, then fetch the latest todo
                          final myUid = toDoService.userId;
                          if (myUid != null) {
                            final snapshot = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(myUid)
                                .collection('todos')
                                .orderBy('toDoName', descending: true)
                                .limit(1)
                                .get();
                            if (snapshot.docs.isNotEmpty) {
                              final todo =
                                  ToDoModel.fromFirestore(snapshot.docs.first);
                              await NotificationService
                                  .scheduleAlarmNotification(
                                id: todo.id.hashCode,
                                dateTime: DateTime.parse(reminderIso),
                                title: todo.toDoName ?? categoryName,
                                body: 'Erinnerung für Ihre Aufgabe',
                                payload: todo.id,
                              );
                            }
                          }
                        }
                        SnackBarHelper.showSuccessSnackBar(
                            context, 'Todo erfolgreich gespeichert');
                        Navigator.of(context).pop(true);
                      }
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
}

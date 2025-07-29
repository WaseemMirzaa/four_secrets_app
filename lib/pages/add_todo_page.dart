import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/category_model.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/category_service.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';
import 'package:four_secrets_wedding_app/services/todo_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';

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
  Map<String, List<String>> allTodo = {};
  List<CategoryModel> allTodoModels = []; // Store full models
  final categoryService = CategoryService();
  String? expandedCategory; // Only one expanded at a time
  Map<String, List<String>> filteredTodo = {};
  bool isLoading = false;
  bool isSaving = false; // For Save button only
  bool isSearching = false;
  Map<String, List<String>> selectedItemsByCategory =
      {}; // Multi-category selection

  bool showFilteredList = false;
  final toDoService = TodoService();

  final _categoryNameController = TextEditingController();
  bool _reminderEnabled = false;
  final _searchController = TextEditingController();
  DateTime? _selectedReminderDate;
  String? _selectedReminderDateText;
  TimeOfDay? _selectedReminderTime;
  String? _selectedReminderTimeText;

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
        final customCategories = await categoryService.getCustomCategories();
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
          // Category not found - fetch all categories and create comprehensive fallback
          print('🟡 ⚠️ Category not found in loaded categories');
          print(
              '🟡 Fetching ALL categories (standard + custom + owner) for comprehensive search');

          try {
            // Fetch all possible categories
            final allStandardCategories =
                await categoryService.getCategories(widget.toDoModel?.userId);
            final allCustomCategories = await categoryService
                .getCustomCategories(widget.toDoModel?.userId);

            // If we have a shared todo, also try to get owner's categories
            List<CategoryModel> ownerCategories = [];
            if (widget.toDoModel?.isShared == true &&
                widget.toDoModel?.userId != null) {
              print(
                  '🟡 Shared todo detected, attempting to fetch owner categories');
              print('🟡 Owner userId: ${widget.toDoModel?.userId}');
              // Note: This would require a method to fetch categories by owner UID
              // For now, we'll use the existing categories
            }

            final comprehensiveCategories = [
              ...allStandardCategories,
              ...allCustomCategories,
              ...ownerCategories
            ];

            print(
                '🟡 Comprehensive search in ${comprehensiveCategories.length} total categories');
            for (var cat in comprehensiveCategories) {
              print(
                  '🟡   - Checking: "${cat.categoryName}" (${cat.todos.length} items)');
            }

            // Search again in the comprehensive list
            CategoryModel? foundCategory;
            try {
              foundCategory = comprehensiveCategories.firstWhere(
                (cat) => cat.categoryName == categoryName,
              );
              print(
                  '🟢 ✅ Category FOUND in comprehensive search: "${foundCategory.categoryName}"');
              print(
                  '🟢 Found category has ${foundCategory.todos.length} items: ${foundCategory.todos}');
              loadTodo = [foundCategory];
            } catch (e) {
              print('🔴 Category still not found in comprehensive search');

              // Final fallback - create category with selected items
              final selectedItems = selectedItemsByCategory[categoryName] ?? [];
              print(
                  '🟡 Creating final fallback with selected items: $selectedItems');

              final fallbackCategory = CategoryModel(
                id: '',
                categoryName: categoryName,
                todos: selectedItems,
                createdAt: DateTime.now(),
                userId: '',
              );
              loadTodo = [fallbackCategory];
              print(
                  '🟡 Created final fallback category "${categoryName}" with ${fallbackCategory.todos.length} items');
            }
          } catch (e) {
            print('� Error during comprehensive category fetch: $e');

            // Emergency fallback
            final selectedItems = selectedItemsByCategory[categoryName] ?? [];
            final emergencyCategory = CategoryModel(
              id: '',
              categoryName: categoryName,
              todos: selectedItems,
              createdAt: DateTime.now(),
              userId: '',
            );
            loadTodo = [emergencyCategory];
            print(
                '🔴 Created emergency fallback category with ${emergencyCategory.todos.length} items');
          }
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
          loadTodo = await categoryService.getCustomCategories();
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
      return "Bearbeiten";
    } else if (widget.showOnlyCustomCategories) {
      return "Eigene To-Do Listen";
    } else {
      return AppConstants.toDoPageTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // backgroundColor: Colors.white,
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: Text(_getAppBarTitle()),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        floatingActionButton: widget.toDoModel == null
            ? FloatingActionButton(
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
              )
            : Container(),
        body: Padding(
          padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
          child: Column(children: [
            if (widget.toDoModel == null)
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
                // onSelected: (suggestion) {
                //   setState(() {
                //     showFilteredList = true;
                //     // If suggestion is a category, set as activeCategory
                //     if (allTodo.containsKey(suggestion)) {
                //       expandedCategory = suggestion;
                //     } else {
                //       // Find which category this item belongs to
                //       final found = allTodo.entries.firstWhere(
                //           (e) => e.value.contains(suggestion),
                //           orElse: () => MapEntry('', []));
                //       if (found.key.isNotEmpty) {
                //         expandedCategory = found.key;
                //       }
                //     }
                //   });
                //   _searchController.text = suggestion;
                //   _searchController.selection = TextSelection.fromPosition(
                //     TextPosition(offset: suggestion.length),
                //   );
                //   FocusScope.of(context).unfocus();
                // },
                onSelected: (suggestion) {
                  setState(() {
                    final lower = suggestion.toLowerCase();
                    filteredTodo = {};
                    allTodo.forEach((cat, items) {
                      final catMatch = cat.toLowerCase().contains(lower);
                      // final itemMatches = items
                      //     .where((item) => item.toLowerCase().contains(lower))
                      //     .toList();
                      if (catMatch) {
                        filteredTodo[cat] = items;
                      }

                      // else if (itemMatches.isNotEmpty) {
                      //   filteredTodo[cat] = itemMatches;
                      // }
                    });
                    showFilteredList = true;
                    if (filteredTodo.isNotEmpty) {
                      expandedCategory = filteredTodo.keys.first;
                    }
                    // Optionally expand the matched category
                    if (allTodo.containsKey(suggestion)) {
                      expandedCategory = suggestion;
                    } else {
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
            // const SpacerWidget(height: 4),
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
                            margin: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ExpansionTile(
                              trailing: (widget.toDoModel != null)
                                  ? null
                                  : SizedBox(width: 0, height: 0),
                              key: ValueKey('$toDoName-$expandedCategory'),
                              // padding: EdgeInsets.zero,
                              tilePadding: EdgeInsets.only(
                                left: 12,
                                right: 12, // Remove right padding to compensate
                                top: 12,
                                bottom: 12,
                              ),
                              showTrailingIcon:
                                  (widget.toDoModel != null) ? true : false,
                              shape: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                              childrenPadding: EdgeInsets.only(
                                  left: 12, right: 0, bottom: 16),
                              initiallyExpanded:
                                  isExpanded || widget.toDoModel != null,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  if (expanded) {
                                    expandedCategory = toDoName;
                                    // Multiple categories can now be selected simultaneously
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomTextWidget(
                                                text: '$toDoName',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (widget.toDoModel == null)
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    // Simple toggle logic that works for both modes
                                                    // Use the same logic as ExpansionTile's onExpansionChanged
                                                    // isExpanded = !isExpanded;
                                                    if (expandedCategory ==
                                                        toDoName) {
                                                      expandedCategory = null;
                                                    } else {
                                                      expandedCategory =
                                                          toDoName;
                                                    }
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(
                                                    20), // Circular touch effect
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                      8), // Increase touch area
                                                  child: AnimatedRotation(
                                                    turns: isExpanded
                                                        ? 0.5
                                                        : 0.0, // Rotate 180 degrees when expanded
                                                    duration: Duration(
                                                        milliseconds: 200),
                                                    child: Icon(
                                                      Icons.keyboard_arrow_down,
                                                      color: !isExpanded
                                                          ? Colors.black
                                                          : Color.fromARGB(255,
                                                              107, 69, 106),
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(
                                          height:
                                              30, // Set explicit height for proper Stack layout
                                          child: Stack(
                                            children: [
                                              // Text positioned on left with padding to avoid button overlap
                                              Positioned.fill(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      right: widget.toDoModel ==
                                                              null
                                                          ? 96
                                                          : 0, // Space for buttons
                                                    ),
                                                    child: CustomTextWidget(
                                                      text:
                                                          '${itemsToDo.length} Unterkategorie${itemsToDo.length != 1 ? 'n' : ''}',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Action buttons positioned on the right
                                              if (widget.toDoModel == null)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          FontAwesomeIcons
                                                              .trashCan,
                                                          color: Colors.red,
                                                          size: 18,
                                                        ),
                                                        tooltip: 'Löschen',
                                                        onPressed: () async {
                                                          var g =
                                                              await showDialog(
                                                                  context:
                                                                      context,
                                                                  builder: (context) =>
                                                                      StatefulBuilder(builder:
                                                                          (context,
                                                                              statee) {
                                                                        return CustomDialog(
                                                                            isLoading:
                                                                                isSaving,
                                                                            title:
                                                                                "Löschen",
                                                                            message:
                                                                                "Möchten Sie diese Liste wirklich löschen?",
                                                                            confirmText:
                                                                                "Löschen",
                                                                            cancelText:
                                                                                "Abbrechen",
                                                                            onConfirm:
                                                                                () async {
                                                                              statee(() {
                                                                                isSaving = true;
                                                                              });
                                                                              try {
                                                                                // Find the category model to get the ID
                                                                                CategoryModel? categoryToDelete = allTodoModels.firstWhere(
                                                                                  (m) => m.categoryName == toDoName,
                                                                                  orElse: () => CategoryModel(
                                                                                    id: '',
                                                                                    categoryName: toDoName,
                                                                                    todos: [],
                                                                                    createdAt: DateTime.now(),
                                                                                    userId: '',
                                                                                  ),
                                                                                );

                                                                                if (categoryToDelete.id.isNotEmpty) {
                                                                                  // Actually delete from database
                                                                                  await categoryService.deleteCategory(categoryToDelete.id);
                                                                                  SnackBarHelper.showSuccessSnackBar(context, 'Kategorie erfolgreich gelöscht');
                                                                                }
                                                                              } catch (e) {
                                                                                print('🔴 Error deleting category: $e');
                                                                                SnackBarHelper.showErrorSnackBar(context, 'Fehler beim Löschen: $e');
                                                                              } finally {
                                                                                statee(() {
                                                                                  isSaving = false;
                                                                                });
                                                                              }
                                                                              Navigator.of(context).pop(true);
                                                                            },
                                                                            onCancel:
                                                                                () {
                                                                              statee(() {
                                                                                isSaving = false;
                                                                              });
                                                                              Navigator.of(context).pop();
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
                                                              todos: itemsToDo,
                                                              createdAt:
                                                                  DateTime
                                                                      .now(),
                                                              userId: '',
                                                            ),
                                                          );
                                                          var g = Navigator.of(
                                                                  context)
                                                              .pushNamed(
                                                            RouteManager
                                                                .addTodoCategoriesPage,
                                                            arguments: {
                                                              "toDoModel":
                                                                  model,
                                                              "id": model.id
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
                                                          color: const Color
                                                              .fromARGB(255,
                                                              107, 69, 106),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                              // Allow multiple categories to be selected simultaneously
                                              print(
                                                  '🟢 Toggling item in category: "$toDoName"');

                                              // Get current items for this category
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
                      // Prepare reminder ISO string if enabled
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
                        // EDITING EXISTING ToDo - Keep original logic for single category
                        final entry = selectedItemsByCategory.entries.first;
                        final categories = [
                          {'categoryName': entry.key, 'items': entry.value}
                        ];

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
                            title: updatedTodo.toDoName ?? entry.key,
                            body: 'Erinnerung für Ihre Aufgabe',
                            payload: updatedTodo.id,
                          );
                        }
                        SnackBarHelper.showSuccessSnackBar(
                            context, 'Todo erfolgreich aktualisiert');
                        Navigator.of(context).pop(true);
                      } else {
                        // CREATING NEW TODOS - Create multiple todos, one for each category
                        int createdCount = 0;
                        List<String> duplicateCategories = [];

                        // Helper method to find existing todo by category name
                        Future<ToDoModel?> _findExistingTodoByCategory(
                            String categoryName) async {
                          final myUid = toDoService.userId;
                          if (myUid == null) return null;

                          try {
                            // Get all todos and search for matching category name
                            final snapshot = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(myUid)
                                .collection('todos')
                                .get();

                            for (final doc in snapshot.docs) {
                              final todo = ToDoModel.fromFirestore(doc);
                              if (todo.categories?.isNotEmpty == true) {
                                for (final category in todo.categories!) {
                                  if (category['categoryName'] ==
                                      categoryName) {
                                    return todo;
                                  }
                                }
                              }
                            }
                            return null;
                          } catch (e) {
                            print('🔴 Error finding existing todo: $e');
                            return null;
                          }
                        }

                        for (final entry in selectedItemsByCategory.entries) {
                          final categoryName = entry.key;
                          final items = entry.value;

                          // Skip empty categories
                          if (items.isEmpty) continue;

                          // Check if category already exists
                          final existingTodo =
                              await _findExistingTodoByCategory(categoryName);

                          if (existingTodo != null) {
                            // Update existing todo by adding new items
                            print(
                                '🟡 Updating existing category: $categoryName');

                            // Get existing items from the category
                            final existingItems =
                                existingTodo.categories?.isNotEmpty == true
                                    ? List<String>.from(existingTodo
                                            .categories!.first['items'] ??
                                        [])
                                    : <String>[];

                            // Add new items that don't already exist
                            final newItems = <String>[];
                            for (final item in items) {
                              if (!existingItems.contains(item)) {
                                newItems.add(item);
                                existingItems.add(item);
                              }
                            }

                            if (newItems.isNotEmpty) {
                              // Update the existing todo with new items
                              final updatedCategories = [
                                {
                                  'categoryName': categoryName,
                                  'items': existingItems
                                }
                              ];

                              final updatedTodo = existingTodo.copyWith(
                                categories: updatedCategories,
                                reminder: reminderIso ??
                                    existingTodo
                                        .reminder, // Keep existing reminder if no new one
                              );

                              await toDoService.updateTodo(updatedTodo);
                              createdCount++; // Count as processed

                              print(
                                  '🟡 Added ${newItems.length} new items to existing category: $categoryName');
                              print('🟡 New items: $newItems');
                            } else {
                              print(
                                  '🟡 No new items to add to category: $categoryName');
                              duplicateCategories
                                  .add(categoryName); // All items already exist
                            }
                          } else {
                            // Create new todo for this category
                            print('🟢 Creating new category: $categoryName');

                            final categories = [
                              {'categoryName': categoryName, 'items': items}
                            ];

                            await toDoService.createTodo(
                              categories: categories,
                              reminder: reminderIso,
                            );

                            createdCount++;
                          }

                          // Schedule local notification if reminder is enabled
                          if (reminderIso != null) {
                            final myUid = toDoService.userId;
                            if (myUid != null) {
                              // For existing todos, we already have the ID, for new ones we need to fetch
                              if (existingTodo != null) {
                                try {
                                  await NotificationService
                                      .scheduleAlarmNotification(
                                    id: existingTodo.id.hashCode,
                                    dateTime: DateTime.parse(reminderIso),
                                    title: categoryName,
                                    body: 'Erinnerung für Ihre Aufgabe',
                                    payload: existingTodo.id,
                                  );
                                  print(
                                      "✅ Todo notification scheduled for: $categoryName");
                                } catch (e) {
                                  print(
                                      "❌ Failed to schedule todo notification: $e");
                                }
                              } else {
                                // For new todos, fetch the latest one
                                final snapshot = await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .doc(myUid)
                                    .collection('todos')
                                    .orderBy('FieldPath.documentId',
                                        descending: true)
                                    .limit(1)
                                    .get();
                                if (snapshot.docs.isNotEmpty) {
                                  final todo = ToDoModel.fromFirestore(
                                      snapshot.docs.first);
                                  await NotificationService
                                      .scheduleAlarmNotification(
                                    id: todo.id.hashCode,
                                    dateTime: DateTime.parse(reminderIso),
                                    title: categoryName,
                                    body: 'Erinnerung für Ihre Aufgabe',
                                    payload: todo.id,
                                  );
                                }
                              }
                            }
                          }
                        }

                        // Show appropriate success/warning message
                        if (createdCount > 0 && duplicateCategories.isEmpty) {
                          SnackBarHelper.showSuccessSnackBar(
                              context,
                              createdCount == 1
                                  ? 'Todo erfolgreich verarbeitet'
                                  : '$createdCount Todos erfolgreich verarbeitet');
                        } else if (createdCount > 0 &&
                            duplicateCategories.isNotEmpty) {
                          SnackBarHelper.showInfoSnackBar(context,
                              '$createdCount Todos verarbeitet. Keine neuen Elemente für: ${duplicateCategories.join(", ")}');
                        } else if (duplicateCategories.isNotEmpty) {
                          SnackBarHelper.showInfoSnackBar(context,
                              'Keine neuen Elemente hinzugefügt. Alle Elemente bereits vorhanden in: ${duplicateCategories.join(", ")}');
                          setState(() => isSaving = false);
                          return;
                        }

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

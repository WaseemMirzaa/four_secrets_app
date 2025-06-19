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
  bool isLoading = false;
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
      });
    }
  }

  Future<void> _loadAndInitCategories() async {
    setState(() {
      isLoading = true;
    });
    try {
      await categoryService.createInitialCategories();
      print('🟢 Starting to load and initialize categories');
      final loadTodo = await categoryService.getCategories();
      print('🟢 Initial todo items created successfully');
      print('🟢 Todos loaded successfully: ${loadTodo.length} items');
      setState(() {
        // Get both the map and the full models
        allTodoModels = loadTodo;

        allTodo = Map.fromEntries(
            loadTodo.map((todo) => MapEntry(todo.categoryName, todo.todos)));
        filteredTodo = Map.from(allTodo);
        isLoading = false;
      });
    } catch (e) {
      print('🔴 Error in _loadAndInitCategories: $e');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, 'Fehler beim Laden der Kategorien: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredTodo = Map.from(allTodo);
      });
    } else {
      final Map<String, List<String>> newFiltered = {};
      allTodo.forEach((category, items) {
        // Search in category name
        bool categoryMatches =
            category.toLowerCase().contains(query.toLowerCase());

        // Search in items
        final matchingItems = items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();

        // Add to filtered results if either category or items match
        if (categoryMatches || matchingItems.isNotEmpty) {
          newFiltered[category] = matchingItems.isEmpty ? items : matchingItems;
        }
      });
      setState(() {
        filteredTodo = newFiltered;
      });
    }
  }

  // Future<void> _showAddSelectedItemsDialog() async {
  //   if (selectedItems.isEmpty) {
  //     SnackBarHelper.showErrorSnackBar(
  //         context, "Bitte wählen Sie mindestens ein Element aus");
  //     return;
  //   }

  //   final TextEditingController categoryController = TextEditingController();
  //   bool isLoading = false;

  //   await showDialog(
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setState) {
  //         return AlertDialog(
  //           contentPadding: EdgeInsets.zero,
  //           content: ClipRRect(
  //             borderRadius: BorderRadius.circular(12),
  //             child: Container(
  //               width: double.maxFinite,
  //               color: Colors.grey.shade100,
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Container(
  //                     padding:
  //                         EdgeInsets.symmetric(horizontal: 15, vertical: 10),
  //                     width: double.infinity,
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Center(
  //                           child: Text(
  //                             "Kategorie aktualisieren",
  //                             style: TextStyle(
  //                               color: Colors.black,
  //                               fontWeight: FontWeight.bold,
  //                               fontSize: 18,
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   if (selectedCategory != null)
  //                     Padding(
  //                       padding:
  //                           EdgeInsets.symmetric(horizontal: 15, vertical: 8),
  //                       child: Text(
  //                         "Ausgewählte Elemente aus: $selectedCategory",
  //                         style: TextStyle(
  //                           color: Colors.grey[600],
  //                           fontSize: 14,
  //                         ),
  //                       ),
  //                     ),
  //                   Padding(
  //                     padding: const EdgeInsets.all(15.0),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Expanded(
  //                           child: CustomButtonWidget(
  //                             text: "Aktualisieren",
  //                             textColor: Colors.white,
  //                             isLoading: isLoading,
  //                             onPressed: () async {
  //                               setState(() => isLoading = true);
  //                               try {
  //                                 // Find the existing category model
  //                                 final existingCategory =
  //                                     allTodoModels.firstWhere(
  //                                   (model) =>
  //                                       model.categoryName == selectedCategory,
  //                                   orElse: () => CategoryModel(
  //                                     id: '',
  //                                     categoryName: selectedCategory ?? '',
  //                                     todos: [],
  //                                     createdAt: DateTime.now(),
  //                                     userId: '',
  //                                   ),
  //                                 );

  //                                 // Update the category with new items
  //                                 final updatedCategory = CategoryModel(
  //                                   id: existingCategory.id,
  //                                   categoryName: existingCategory.categoryName,
  //                                   todos: selectedItems,
  //                                   createdAt: existingCategory.createdAt,
  //                                   userId: existingCategory.userId,
  //                                 );

  //                                 // Update the category
  //                                 await categoryService
  //                                     .updateCategory(updatedCategory);

  //                                 // Get the associated todo for this category
  //                                 final todos = await toDoService
  //                                     .getTodosByCategory(updatedCategory.id);

  //                                 if (todos.isNotEmpty) {
  //                                   // Update existing todo
  //                                   final todo = todos.first;
  //                                   final updatedTodo = ToDoModel(
  //                                     id: todo.id,
  //                                     toDoName: existingCategory.categoryName,
  //                                     toDoItems: selectedItems,
  //                                     userId: todo.userId,
  //                                     collaborators: todo.collaborators,
  //                                     comments: todo.comments,
  //                                   );
  //                                   await toDoService.updateTodo(updatedTodo);
  //                                 }

  //                                 if (context.mounted) {
  //                                   Navigator.of(context).pop();
  //                                   _loadAndInitCategories();
  //                                   selectedItems.clear();
  //                                   selectedCategory = null;
  //                                   SnackBarHelper.showSuccessSnackBar(context,
  //                                       "Kategorie erfolgreich aktualisiert");
  //                                 }
  //                               } catch (e) {
  //                                 if (context.mounted) {
  //                                   SnackBarHelper.showErrorSnackBar(context,
  //                                       "Fehler beim Aktualisieren: $e");
  //                                 }
  //                               } finally {
  //                                 setState(() => isLoading = false);
  //                               }
  //                             },
  //                           ),
  //                         ),
  //                         SizedBox(width: 10),
  //                         Expanded(
  //                           child: CustomButtonWidget(
  //                             text: "Abbrechen",
  //                             color: Colors.white,
  //                             textColor: Colors.black,
  //                             onPressed: () => Navigator.of(context).pop(),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

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
            }
          },
          child: Icon(Icons.add),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(children: [
            CustomTextField(
              controller: _searchController,
              onchanged: (value) {
                _onSearchChanged(value);
              },
              inputDecoration: InputDecoration(
                prefixIcon: Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Colors.grey.withValues(alpha: 0.8),
                ),
                hintText: "suchen...",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.8),
                    ),
                    borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.8),
                    ),
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.8),
                    ),
                    borderRadius: BorderRadius.circular(8)),
              ),
              label: 'suchen...',
            ),
            // if (_searchController.text.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(vertical: 8.0),
            //     child: CustomTextWidget(
            //       text: '${filteredTodo.length} Kategorien gefunden',
            //       color: Colors.grey[600],
            //       fontSize: 14,
            //     ),
            //   ),
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
                                    horizontal: 1,
                                    vertical: 5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    CustomTextWidget(
                                                      text: toDoName,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                            // Delete associated invitations first
                                                            final invitations =
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'invitations')
                                                                    .where(
                                                                        'todoId',
                                                                        isEqualTo:
                                                                            allTodoModels[index].id)
                                                                    .get();

                                                            // Delete each invitation
                                                            for (var doc
                                                                in invitations
                                                                    .docs) {
                                                              await doc
                                                                  .reference
                                                                  .delete();
                                                            }

                                                            // Then delete the category
                                                            await categoryService
                                                                .deleteCategory(
                                                              allTodoModels[
                                                                      index]
                                                                  .id,
                                                            );
                                                            _loadAndInitCategories();
                                                          } catch (e) {
                                                            if (mounted) {
                                                              SnackBarHelper
                                                                  .showErrorSnackBar(
                                                                      context,
                                                                      "Fehler beim Löschen: $e");
                                                            }
                                                          }
                                                        },
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selectedItems.isNotEmpty &&
                                              selectedCategory == toDoName)
                                            IconButton(
                                              icon: Icon(
                                                Icons.add,
                                                size: 20,
                                                color: Colors.black,
                                              ),
                                              onPressed: () async {
                                                try {
                                                  final updatedCategory =
                                                      CategoryModel(
                                                    id: allTodoModels[index].id,
                                                    categoryName: toDoName,
                                                    todos: selectedItems,
                                                    createdAt:
                                                        allTodoModels[index]
                                                            .createdAt,
                                                    userId: allTodoModels[index]
                                                        .userId,
                                                  );

                                                  // Update the category
                                                  await categoryService
                                                      .updateCategory(
                                                          updatedCategory);

                                                  // Get all todos and find the one matching this category name
                                                  final allTodos =
                                                      await toDoService
                                                          .getTodos();
                                                  final existingTodo =
                                                      allTodos.firstWhere(
                                                    (todo) =>
                                                        todo.toDoName ==
                                                        toDoName,
                                                    orElse: () => ToDoModel(
                                                      id: '',
                                                      toDoName: toDoName,
                                                      toDoItems: [],
                                                      userId: '',
                                                      collaborators: [],
                                                      comments: [],
                                                    ),
                                                  );

                                                  if (existingTodo
                                                      .id.isNotEmpty) {
                                                    // Update existing todo
                                                    final updatedTodo =
                                                        ToDoModel(
                                                      id: existingTodo.id,
                                                      toDoName: toDoName,
                                                      toDoItems: selectedItems
                                                          .map((item) => {
                                                                'name': item,
                                                                'isChecked': existingTodo.toDoItems.firstWhere(
                                                                        (i) =>
                                                                            i['name'] ==
                                                                            item,
                                                                        orElse: () =>
                                                                            {
                                                                              'isChecked': false
                                                                            })['isChecked'] ??
                                                                    false,
                                                              })
                                                          .toList(),
                                                      userId:
                                                          existingTodo.userId,
                                                      collaborators:
                                                          existingTodo
                                                              .collaborators,
                                                      comments:
                                                          existingTodo.comments,
                                                    );
                                                    await toDoService
                                                        .updateTodo(
                                                            updatedTodo);
                                                  } else {
                                                    // Create new todo if none exists
                                                    await toDoService
                                                        .createTodo(
                                                      toDoName,
                                                      selectedItems,
                                                      updatedCategory.id,
                                                    );
                                                  }

                                                  // Clear selection
                                                  setState(() {
                                                    selectedItems.clear();
                                                    selectedCategory = null;
                                                  });

                                                  // Refresh the data
                                                  Navigator.of(context)
                                                      .pop(true);

                                                  if (mounted) {
                                                    SnackBarHelper
                                                        .showSuccessSnackBar(
                                                            context,
                                                            "Todo erfolgreich aktualisiert");
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    SnackBarHelper
                                                        .showErrorSnackBar(
                                                            context,
                                                            "Fehler beim Aktualisieren: $e");
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
                                                        m.categoryName ==
                                                        toDoName,
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
                                                ))
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ...itemsToDo.map((item) {
                                        final isSelected =
                                            selectedItems.contains(item);
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey
                                                .withValues(alpha: 0.2),
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
                                                          selectedCategory =
                                                              null;
                                                        }
                                                      } else {
                                                        selectedItems.add(item);
                                                        selectedCategory =
                                                            toDoName;

                                                        print(selectedItems);
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
                                                                ? Color
                                                                    .fromARGB(
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
                                                                    .circular(
                                                                        4),
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
                                                          child:
                                                              CustomTextWidget(
                                                            text: " $item",
                                                            fontSize: 14,
                                                            color: isSelected
                                                                ? Color
                                                                    .fromARGB(
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
                                      // SpacerWidget(height: 15)
                                    ],
                                  ),
                                );
                              },
                            ),
            )
          ]),
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
                  onTap: () {
                    // Add haptic feedback
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(item);
                  },
                  borderRadius: BorderRadius.circular(16),
                  splashColor:
                      Color.fromARGB(255, 107, 69, 106).withOpacity(0.1),
                  highlightColor:
                      Color.fromARGB(255, 107, 69, 106).withOpacity(0.05),
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

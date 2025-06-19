import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/category_model.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/todo_service.dart';
import 'package:four_secrets_wedding_app/services/auth_service.dart';
import 'package:four_secrets_wedding_app/services/collaboration_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final toDoService = TodoService();
  final authService = AuthService();
  final key = GlobalKey<MenueState>();
  final collaborationService = CollaborationService();
  bool isLoading = false;
  List<ToDoModel> listToDoModel = [];
  Map<String, dynamic> toDoList = {};
  List<String> selectedItems = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadAndInitCategories();
  }

  Future<void> _loadAndInitCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      final todos = await toDoService.getTodos();
      setState(() {
        listToDoModel = todos;
        toDoList = Map.fromEntries(
            todos.map((todo) => MapEntry(todo.toDoName, todo.toDoItems)));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(context, "Error loading todos: $e");
      }
    }
  }

  Future<void> _showInviteDialog(String todoId, String todoName) async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    final currentUser = FirebaseAuth.instance.currentUser;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.maxFinite,
                color: Colors.grey.shade100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              "Benutzer einladen",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          hintText: "Name oder E-Mail suchen",
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (value) async {
                          if (value.length >= 2) {
                            setState(() => isSearching = true);
                            try {
                              final results =
                                  await authService.searchUsers(value);
                              // Filter out the current user and existing collaborators from results
                              final todo = listToDoModel.firstWhere(
                                (t) => t.id == todoId,
                                orElse: () => ToDoModel(
                                  id: todoId,
                                  toDoName: todoName,
                                  toDoItems: [],
                                  userId: '',
                                  collaborators: [],
                                  comments: [],
                                ),
                              );
                              final filteredResults = results
                                  .where((user) =>
                                      user['uid'] != currentUser?.uid &&
                                      !todo.collaborators.contains(user['uid']))
                                  .toList();
                              setState(() {
                                searchResults = filteredResults;
                                isSearching = false;
                              });
                            } catch (e) {
                              setState(() => isSearching = false);
                              if (context.mounted) {
                                SnackBarHelper.showErrorSnackBar(
                                    context, "Fehler bei der Suche: $e");
                              }
                            }
                          } else {
                            setState(() => searchResults = []);
                          }
                        },
                      ),
                    ),
                    if (isSearching)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (!isSearching && searchResults.isNotEmpty)
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            return ListTile(
                              title: Text(user['name']),
                              subtitle: Text(user['email']),
                              trailing: IconButton(
                                icon: Icon(Icons.person_add,
                                    color: Color.fromARGB(255, 107, 69, 106)),
                                onPressed: () async {
                                  try {
                                    await collaborationService.sendInvitation(
                                      todoId: todoId,
                                      todoName: todoName,
                                      inviteeId: user['uid'],
                                      inviteeName: user['name'],
                                    );

                                    // Refresh the data before closing the dialog
                                    await _loadAndInitCategories();

                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      SnackBarHelper.showSuccessSnackBar(
                                          context,
                                          "Einladung erfolgreich gesendet");
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      SnackBarHelper.showErrorSnackBar(context,
                                          "Fehler beim Senden der Einladung: $e");
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CustomButtonWidget(
                              text: "Abbrechen",
                              color: Colors.white,
                              textColor: Colors.black,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddSelectedItemsDialog() async {
    if (selectedItems.isEmpty) {
      SnackBarHelper.showErrorSnackBar(
          context, "Bitte wählen Sie mindestens ein Element aus");
      return;
    }

    final TextEditingController categoryController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.maxFinite,
                color: Colors.grey.shade100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              "Neue Kategorie erstellen",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        controller: categoryController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          hintText: "Kategorie Name",
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CustomButtonWidget(
                              text: "Hinzufügen",
                              textColor: Colors.white,
                              isLoading: isLoading,
                              onPressed: () async {
                                if (categoryController.text.isEmpty) {
                                  SnackBarHelper.showErrorSnackBar(context,
                                      "Bitte geben Sie einen Kategorienamen ein");
                                  return;
                                }
                                setState(() => isLoading = true);
                                try {
                                  await toDoService.createTodo(
                                    categoryController.text,
                                    selectedItems,
                                    '',
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    _loadAndInitCategories();
                                    selectedItems.clear();
                                    selectedCategory = null;
                                    SnackBarHelper.showSuccessSnackBar(context,
                                        "Kategorie erfolgreich erstellt");
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackBarHelper.showErrorSnackBar(
                                        context, "Fehler beim Erstellen: $e");
                                  }
                                } finally {
                                  setState(() => isLoading = false);
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: CustomButtonWidget(
                              text: "Abbrechen",
                              color: Colors.white,
                              textColor: Colors.black,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      drawer: Menue.getInstance(key),
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(AppConstants.toDoPageTitle),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        actions: [
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _showAddSelectedItemsDialog,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var g = await Navigator.pushNamed(context, RouteManager.addToDoPage,
              arguments: {
                "toDoModel": null,
                "id": null,
              });
          if (g == true) {
            _loadAndInitCategories();
          }
        },
        child: Icon(Icons.add),
      ),
      body: ListView(
        children: [
          Image.asset("assets/images/background/todoBg.jpeg"),
          SpacerWidget(height: 5),
          FourSecretsDivider(),
          if (isLoading)
            Center(
              child: CircularProgressIndicator.adaptive(),
            )
          else
            ...toDoList.entries.map((entry) {
              String toDoName = entry.key;
              List<Map<String, dynamic>> itemsToDo = listToDoModel
                  .firstWhere((todo) => todo.toDoName == toDoName)
                  .toDoItems;
              int index =
                  listToDoModel.indexWhere((todo) => todo.toDoName == toDoName);
              if (index == -1) index = 0; // Fallback to first item if not found
              return Slidable(
                endActionPane: ActionPane(
                  motion: const StretchMotion(),
                  children: [
                    SlidableAction(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      onPressed: (_) async {
                        try {
                          // First delete any associated collaboration todos
                          final collaborationSnapshot = await FirebaseFirestore
                              .instance
                              .collection('collaboration_todos')
                              .where('todoId',
                                  isEqualTo: listToDoModel[index].id)
                              .get();

                          // Delete all associated collaboration todos
                          for (var doc in collaborationSnapshot.docs) {
                            await doc.reference.delete();
                          }

                          // Then delete the main todo
                          await toDoService.deleteTodo(
                            listToDoModel[index].id,
                          );
                          setState(() {
                            listToDoModel.removeAt(index);
                            toDoList.remove(toDoName);
                          });
                        } catch (e) {
                          if (context.mounted) {
                            SnackBarHelper.showErrorSnackBar(
                                context, e.toString());
                          }
                        }
                      },
                      icon: Icons.delete,
                      backgroundColor: Colors.red.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    shape: OutlineInputBorder(borderSide: BorderSide.none),
                    childrenPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                toDoName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              CustomTextWidget(
                                text:
                                    '${itemsToDo.length} Unterkategorie${itemsToDo.length != 1 ? 'n' : ''} • ${listToDoModel[index].collaborators.length} Mitarbeiter${listToDoModel[index].collaborators.length != 1 ? '' : ''}',
                                fontWeight: FontWeight.w500,
                              )
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            ToDoModel? model = listToDoModel.firstWhere(
                              (m) => m.toDoName == toDoName,
                              orElse: () => ToDoModel(
                                id: '',
                                toDoName: toDoName,
                                toDoItems: [],
                                userId: '',
                                collaborators: [],
                                comments: [],
                              ),
                            );

                            Navigator.of(context).pushNamed(
                              RouteManager.addToDoPage,
                              arguments: {"toDoModel": model, "id": model.id},
                            ).then((v) {
                              _loadAndInitCategories();
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.person_add,
                            size: 20,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            _showInviteDialog(
                              listToDoModel[index].id,
                              toDoName,
                            );
                          },
                        ),
                      ],
                    ),
                    children: itemsToDo.map((item) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                width: context.screenWidth,
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item['isChecked'] ?? false,
                                      onChanged: (bool? value) async {
                                        try {
                                          final updatedTodo =
                                              listToDoModel[index]
                                                  .toggleItemChecked(
                                                      item['name']);
                                          await toDoService
                                              .updateTodo(updatedTodo);
                                          setState(() {
                                            listToDoModel[index] = updatedTodo;
                                          });
                                        } catch (e) {
                                          if (context.mounted) {
                                            SnackBarHelper.showErrorSnackBar(
                                                context,
                                                "Failed to update item: $e");
                                          }
                                        }
                                      },
                                      activeColor: const Color.fromARGB(
                                          255, 107, 69, 106),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: CustomTextWidget(
                                        text: "${item['name']}",
                                        fontSize: 14,
                                        color: Colors.black,
                                        decoration: item['isChecked'] == true
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          SpacerWidget(height: 1),
          listToDoModel.isEmpty ? AbsorbPointer() : FourSecretsDivider(),
          SpacerWidget(height: 10),
        ],
      ),
    ));
  }
}

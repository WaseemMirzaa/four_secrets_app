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
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final todos = await toDoService.getTodos();
      if (mounted) {
        setState(() {
          listToDoModel = todos;
          toDoList = Map.fromEntries(
              todos.map((todo) => MapEntry(todo.toDoName, todo.toDoItems)));
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        SnackBarHelper.showErrorSnackBar(context, "Error loading todos: $e");
      }
    }
  }

  Future<void> _showInviteDialog(String todoId, String todoName) async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    bool isSendingInvite = false;
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
                              trailing: isSendingInvite
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : IconButton(
                                      icon: Icon(Icons.person_add,
                                          color: Color.fromARGB(
                                              255, 107, 69, 106)),
                                      onPressed: isSendingInvite
                                          ? null
                                          : () async {
                                              setState(
                                                  () => isSendingInvite = true);
                                              try {
                                                await collaborationService
                                                    .sendInvitation(
                                                  todoId: todoId,
                                                  todoName: todoName,
                                                  inviteeId: user['uid'],
                                                  inviteeName: user['name'],
                                                );
                                                // Refresh the data before closing the dialog
                                                await _loadAndInitCategories();
                                                if (context.mounted) {
                                                  Navigator.of(context).pop();
                                                  SnackBarHelper
                                                      .showSuccessSnackBar(
                                                          context,
                                                          "Einladung erfolgreich gesendet");
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  SnackBarHelper.showErrorSnackBar(
                                                      context,
                                                      "Fehler beim Senden der Einladung: $e");
                                                }
                                              } finally {
                                                if (mounted)
                                                  setState(() =>
                                                      isSendingInvite = false);
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
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        // backgroundColor: cons,
        overlayColor: Colors.transparent,
        overlayOpacity: 0.0,
        children: [
          SpeedDialChild(
            child: Icon(Icons.list_alt, color: Colors.white),
            backgroundColor: const Color.fromARGB(255, 107, 69, 106),
            label: 'Mit Vorlage starten',
            labelStyle: TextStyle(fontSize: 16),
            onTap: () async {
              var g = await Navigator.pushNamed(
                context,
                RouteManager.addToDoPage,
                arguments: {
                  "toDoModel": ToDoModel(
                    id: '',
                    toDoName: '',
                    toDoItems:
                        [].map((e) => {'name': e, 'isChecked': false}).toList(),
                    userId: '',
                    collaborators: [],
                    comments: [],
                  ),
                  "id": null,
                },
              );
              if (g == true) {
                _loadAndInitCategories();
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.add, color: Colors.white),
            backgroundColor: const Color.fromARGB(255, 107, 69, 106),
            label: 'Mit leerer Liste starten',
            labelStyle: TextStyle(fontSize: 16),
            onTap: () async {
              Navigator.pushNamed(context, RouteManager.customTodoCategoryPage);
              _loadAndInitCategories();
            },
          ),
        ],
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
          else if (toDoList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Center(
                child: CustomTextWidget(
                    textAlign: TextAlign.center,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    text:
                        "Noch Keine Punkte hinzugefügt. Tippe auf das + Symbol unten rechts."),
              ),
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
                            listToDoModel[index].id!,
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
                                    '${itemsToDo.length} Punkte${itemsToDo.length != 1 ? 'n' : ''} • ${listToDoModel[index].collaborators.length} Mitgestalter${listToDoModel[index].collaborators.length != 1 ? '' : ''}',
                                fontWeight: FontWeight.w500,
                              ),
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
                            ToDoModel? model = listToDoModel[index];
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
                              listToDoModel[index].id!,
                              toDoName,
                            );
                          },
                        ),
                      ],
                    ),
                    children: [
                      // Reminder row at the top of children
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 8),
                            if (listToDoModel[index].reminder != null &&
                                listToDoModel[index].reminder!.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  final reminder = DateTime.tryParse(
                                      listToDoModel[index].reminder!);
                                  if (reminder == null) return SizedBox();
                                  return Text(
                                    '${reminder.day.toString().padLeft(2, '0')}.${reminder.month.toString().padLeft(2, '0')}.${reminder.year} - '
                                    '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.deepPurple),
                                  );
                                },
                              )
                            else
                              Expanded(
                                child: Text('Kein Reminder gesetzt',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              ),
                            IconButton(
                              icon: Icon(Icons.alarm_add,
                                  color: Colors.deepPurple),
                              tooltip: listToDoModel[index].reminder == null
                                  ? 'Add reminder'
                                  : 'Edit reminder',
                              onPressed: () async {
                                DateTime now = DateTime.now();
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: listToDoModel[index].reminder !=
                                              null &&
                                          listToDoModel[index]
                                              .reminder!
                                              .isNotEmpty
                                      ? DateTime.tryParse(
                                              listToDoModel[index].reminder!) ??
                                          now
                                      : now,
                                  firstDate: now,
                                  lastDate: DateTime(now.year + 5),
                                );
                                if (pickedDate != null) {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        listToDoModel[index].reminder != null &&
                                                listToDoModel[index]
                                                    .reminder!
                                                    .isNotEmpty
                                            ? TimeOfDay.fromDateTime(
                                                DateTime.tryParse(
                                                        listToDoModel[index]
                                                            .reminder!) ??
                                                    now)
                                            : TimeOfDay.now(),
                                  );
                                  if (pickedTime != null) {
                                    final reminderDateTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                    try {
                                      final updatedTodo = listToDoModel[index]
                                          .copyWith(
                                              reminder: reminderDateTime
                                                  .toIso8601String());
                                      await toDoService.updateTodo(updatedTodo);
                                      setState(() {
                                        listToDoModel[index] = updatedTodo;
                                      });
                                    } catch (e) {
                                      if (context.mounted) {
                                        SnackBarHelper.showErrorSnackBar(
                                            context,
                                            "Failed to set reminder: $e");
                                      }
                                    }
                                  }
                                }
                              },
                            ),
                            if (listToDoModel[index].reminder != null &&
                                listToDoModel[index].reminder!.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.close,
                                    size: 20, color: Colors.red),
                                tooltip: 'Remove reminder',
                                onPressed: () async {
                                  try {
                                    final updatedTodo = listToDoModel[index]
                                        .copyWith(reminder: null);
                                    await toDoService.updateTodo(updatedTodo);
                                    setState(() {
                                      listToDoModel[index] = updatedTodo;
                                    });
                                  } catch (e) {
                                    if (context.mounted) {
                                      SnackBarHelper.showErrorSnackBar(context,
                                          "Failed to remove reminder: $e");
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      ...itemsToDo.map((item) {
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
                                              listToDoModel[index] =
                                                  updatedTodo;
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
                    ],
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

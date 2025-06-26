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
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:four_secrets_wedding_app/pages/collaboration_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:four_secrets_wedding_app/services/collaboration_todo_service.dart';
import 'package:four_secrets_wedding_app/model/collaboration_todo_model.dart';
import '../widgets/collaboration_todo_tile.dart';

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
  bool isDeleting = false;
  bool hasNewCollabNotification = false;
  List<CollaborationTodoModel> acceptedCollaborations = [];
  List<CollaborationTodoModel> receivedCollaborations = [];

  @override
  void initState() {
    super.initState();
    _loadAndInitCategories();
    _loadCollaborationData();
    _checkUnreadNotifications();
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
          toDoList = Map.fromEntries(todos
              .map((todo) => MapEntry(todo.id ?? '', todo.toDoItems ?? [])));
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

  Future<void> _loadCollaborationData() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final firestore = FirebaseFirestore.instance;
    // Accepted collaborations (where user is a collaborator)
    final collaboratedSnapshot = await firestore
        .collection('collaboration_todos')
        .where('collaborators', arrayContains: myUid)
        .get();
    acceptedCollaborations = collaboratedSnapshot.docs.map((doc) {
      return CollaborationTodoModel.fromFirestore(doc);
    }).toList();
    // Received collaborations (where user is the owner and others collaborate)
    final ownedSnapshot = await firestore
        .collection('collaboration_todos')
        .where('ownerId', isEqualTo: myUid)
        .get();
    receivedCollaborations = ownedSnapshot.docs
        .map((doc) => CollaborationTodoModel.fromFirestore(doc))
        .where((todo) => (todo.collaborators.isNotEmpty))
        .toList();
    // Notification logic: if there are any new/received collaborations
    hasNewCollabNotification = acceptedCollaborations.isNotEmpty;
    if (mounted) setState(() {});
  }

  Future<void> _checkUnreadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('token', isEqualTo: fcmToken)
        .where('read', isEqualTo: false)
        .get();
    // Only set to true if there is an unread invitation notification
    final hasInvite = snapshot.docs
        .any((doc) => (doc.data()['data']?['type'] ?? '') == 'invitation');
    setState(() {
      hasNewCollabNotification = hasInvite;
    });
  }

  Future<void> _showInviteDialog() async {
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
                              // Filter out the current user from results (no per-todo collaborators)
                              final filteredResults = results
                                  .where(
                                      (user) => user['uid'] != currentUser?.uid)
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
                                                    .sendInvitationForAllTodos(
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
                                                          "Einladung für alle Listen gesendet");
                                                }
                                              } catch (e) {
                                                SnackBarHelper.showErrorSnackBar(
                                                    context,
                                                    "Fehler beim Senden der Einladung: $e");
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
                                    categories: [
                                      {
                                        'categoryName': categoryController.text,
                                        'items': selectedItems,
                                      },
                                    ],
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
                                  print("🟢 e: $e");
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

  List<Map<String, dynamic>> sanitizeCategories(
      List<Map<String, dynamic>> categories) {
    return categories.map((cat) {
      final sanitizedItems = (cat['items'] as List).map((item) {
        if (item is Map<String, dynamic>) return item;
        if (item is Map) return Map<String, dynamic>.from(item);
        return {'name': item.toString(), 'isChecked': false};
      }).toList();
      return {
        'categoryName': cat['categoryName'],
        'items': sanitizedItems,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return SafeArea(
        child: Scaffold(
      drawer: Menue.getInstance(key),
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text(AppConstants.toDoPageTitle),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.group),
                tooltip: 'Zusammenarbeit',
                onPressed: () async {
                  setState(() {
                    hasNewCollabNotification = false;
                  });
                  var g = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CollaborationScreen()),
                  );
                  if (g == true) {
                    _loadCollaborationData();
                  }
                  _checkUnreadNotifications();
                },
              ),
              if (hasNewCollabNotification)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            tooltip: 'Alle Listen teilen',
            onPressed: _showInviteDialog,
          ),
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _showAddSelectedItemsDialog,
            ),
        ],
      ),
      floatingActionButton: SpeedDial(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                  "toDoModel": null,
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
          // Always show accepted/collaborated section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Akzeptierte Zusammenarbeiten',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (acceptedCollaborations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Keine Einträge',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ...acceptedCollaborations.map((collab) {
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('collaboration_todos')
                        .doc(collab.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return SizedBox();
                      }

                      return CollaborationTodoTile(
                        collabId: collab.id,
                        color: Colors.grey.withValues(alpha: 0.2),
                        labelColor: Color.fromARGB(255, 107, 69, 106)
                            .withValues(alpha: 0.8),
                        labelTextColor: Colors.white,
                        checkboxColor: Color.fromARGB(255, 107, 69, 106),
                        avatarColor: Color.fromARGB(255, 107, 69, 106)
                            .withValues(alpha: 0.4),
                      );
                    },
                  );
                }),
              ],
            ),
          ),

          SpacerWidget(height: 2),
          FourSecretsDivider(),
          // Sent Collaborations section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gesendete Zusammenarbeiten',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (receivedCollaborations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Keine Einträge',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ...receivedCollaborations.map((collab) {
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('collaboration_todos')
                        .doc(collab.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return SizedBox();
                      }

                      return CollaborationTodoTile(
                        collabId: collab.id,
                        color: Colors.grey.withValues(alpha: 0.2),
                        labelColor: Color.fromARGB(255, 107, 69, 106)
                            .withValues(alpha: 0.8),
                        labelTextColor: Colors.white,
                        checkboxColor: Color.fromARGB(255, 107, 69, 106),
                        avatarColor: Color.fromARGB(255, 107, 69, 106)
                            .withValues(alpha: 0.4),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
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
            SpacerWidget(height: 2),
          FourSecretsDivider(),
          ...toDoList.entries.map((entry) {
            String todoId = entry.key;
            // Use manual search to avoid linter error
            ToDoModel? todoModel;
            for (final todo in listToDoModel) {
              if ((todo.id ?? '') == todoId) {
                todoModel = todo;
                break;
              }
            }
            if (todoModel == null) return SizedBox();
            String toDoName = todoModel.toDoName ?? '';
            List<Map<String, dynamic>> itemsToDo = todoModel.toDoItems ?? [];
            int index = listToDoModel.indexWhere((todo) => todo.id == todoId);
            if (index == -1) index = 0;
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5,
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
                            (todoModel.categories != null &&
                                    todoModel.categories!.isNotEmpty &&
                                    todoModel.categories![0]['categoryName'] !=
                                        null &&
                                    todoModel.categories![0]['categoryName']
                                        .toString()
                                        .isNotEmpty)
                                ? todoModel.categories![0]['categoryName']
                                : toDoName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CustomTextWidget(
                            text:
                                '${(todoModel.categories != null && todoModel.categories!.isNotEmpty) ? todoModel.categories!.fold(0, (sum, cat) => sum + ((cat['items'] as List?)?.length ?? 0)) : (todoModel.toDoItems?.length ?? 0)} Punkte${((todoModel.categories != null && todoModel.categories!.isNotEmpty) ? todoModel.categories!.fold(0, (sum, cat) => sum + ((cat['items'] as List?)?.length ?? 0)) : (todoModel.toDoItems?.length ?? 0)) != 1 ? 'n' : ''} • ${todoModel.collaborators.length} Mitgestalter${todoModel.collaborators.length != 1 ? '' : ''}',
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 20,
                        color: const Color.fromARGB(255, 107, 69, 106),
                      ),
                      onPressed: () {
                        ToDoModel? model = todoModel;
                        Navigator.of(context).pushNamed(
                          RouteManager.addToDoPage,
                          arguments: {"toDoModel": model, "id": model?.id},
                        ).then((v) {
                          _loadAndInitCategories();
                        });
                      },
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 8),
                        if (todoModel?.reminder != null &&
                            todoModel?.reminder!.isNotEmpty == true)
                          Builder(
                            builder: (context) {
                              final reminder =
                                  DateTime.tryParse(todoModel?.reminder ?? '');
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
                          icon: Icon(Icons.alarm_add, color: Colors.deepPurple),
                          tooltip: todoModel?.reminder == null
                              ? 'Add reminder'
                              : 'Edit reminder',
                          onPressed: () async {
                            DateTime now = DateTime.now();
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: todoModel?.reminder != null &&
                                      todoModel?.reminder!.isNotEmpty == true
                                  ? DateTime.tryParse(
                                          todoModel?.reminder ?? '') ??
                                      now
                                  : now,
                              firstDate: now,
                              lastDate: DateTime(now.year + 5),
                            );
                            if (pickedDate != null) {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: todoModel?.reminder != null &&
                                        todoModel?.reminder!.isNotEmpty == true
                                    ? TimeOfDay.fromDateTime(DateTime.tryParse(
                                            todoModel?.reminder ?? '') ??
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
                                  final updatedTodo = todoModel?.copyWith(
                                      reminder:
                                          reminderDateTime.toIso8601String());
                                  if (updatedTodo != null) {
                                    await toDoService.updateTodo(updatedTodo);
                                    print('Updated todo in Firestore: ' +
                                        updatedTodo.toMap().toString());
                                    await _loadAndInitCategories();
                                    setState(() {
                                      listToDoModel[index] = updatedTodo;
                                    });
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackBarHelper.showErrorSnackBar(
                                        context, "Failed to set reminder: $e");
                                  }
                                }
                              }
                            }
                          },
                        ),
                        if (todoModel?.reminder != null &&
                            todoModel?.reminder!.isNotEmpty == true)
                          IconButton(
                            icon:
                                Icon(Icons.close, size: 20, color: Colors.red),
                            tooltip: 'Remove reminder',
                            onPressed: () async {
                              try {
                                final updatedTodo =
                                    todoModel?.copyWith(reminder: null);
                                if (updatedTodo != null) {
                                  await toDoService.updateTodo(updatedTodo);
                                  await _loadAndInitCategories();
                                  setState(() {
                                    listToDoModel[index] = updatedTodo;
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  SnackBarHelper.showErrorSnackBar(
                                      context, "Failed to remove reminder: $e");
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  if (todoModel?.categories != null &&
                      todoModel?.categories!.isNotEmpty == true)
                    ...List.generate(todoModel?.categories!.length ?? 0,
                        (catIdx) {
                      var cat = todoModel!.categories![catIdx];
                      var items = (cat['items'] as List);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(items.length, (itemIdx) {
                            var itemRaw = items[itemIdx];
                            Map<String, dynamic> item;
                            if (itemRaw is String) {
                              item = {'name': itemRaw, 'isChecked': false};
                            } else if (itemRaw is Map<String, dynamic>) {
                              item = itemRaw;
                            } else if (itemRaw is Map) {
                              item = Map<String, dynamic>.from(itemRaw);
                            } else {
                              item = {
                                'name': itemRaw.toString(),
                                'isChecked': false
                              };
                            }
                            final itemName = item['name'] ?? '';
                            final isChecked = item['isChecked'] ?? false;
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    onChanged: (bool? value) async {
                                      try {
                                        var categoriesCopy =
                                            List<Map<String, dynamic>>.from(
                                                todoModel!.categories!);
                                        var itemsCopy = (categoriesCopy[catIdx]
                                                ['items'] as List)
                                            .map((e) =>
                                                e is Map<String, dynamic>
                                                    ? e
                                                    : {
                                                        'name': e.toString(),
                                                        'isChecked': false
                                                      })
                                            .toList();
                                        itemsCopy[itemIdx] = {
                                          ...item,
                                          'isChecked':
                                              !(item['isChecked'] ?? false),
                                        };
                                        categoriesCopy[catIdx]['items'] =
                                            itemsCopy;
                                        categoriesCopy =
                                            sanitizeCategories(categoriesCopy);
                                        final updatedTodo = todoModel?.copyWith(
                                            categories: categoriesCopy);
                                        if (updatedTodo != null) {
                                          await toDoService
                                              .updateTodo(updatedTodo);
                                          setState(() {
                                            listToDoModel[index] = updatedTodo;
                                          });
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          SnackBarHelper.showErrorSnackBar(
                                              context,
                                              "Failed to update item: $e");
                                        }
                                      }
                                    },
                                    activeColor: Colors.purple,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextWidget(
                                      text: itemName,
                                      fontSize: 14,
                                      color: Colors.black,
                                      decoration: isChecked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  Divider(),
                  SpacerWidget(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    child: CustomButtonWidget(
                      text: "Löschen",
                      width: context.screenWidth,
                      color: Colors.red.shade300,
                      textColor: Colors.white,
                      onPressed: () async {
                        var g = await showDialog(
                            context: context,
                            builder: (context) =>
                                StatefulBuilder(builder: (context, statee) {
                                  return CustomDialog(
                                      isLoading: isDeleting,
                                      title: "Löschen",
                                      message:
                                          "Möchtest du diesen Punkt wirklich löschen?",
                                      confirmText: "Löschen",
                                      cancelText: "Abbrechen",
                                      onConfirm: () async {
                                        statee(() {
                                          isDeleting = true;
                                        });
                                        try {
                                          // First delete any associated collaboration todos
                                          final collaborationSnapshot =
                                              await FirebaseFirestore.instance
                                                  .collection(
                                                      'collaboration_todos')
                                                  .where('todoId',
                                                      isEqualTo:
                                                          todoModel?.id ?? '')
                                                  .get();

                                          // Delete all associated collaboration todos
                                          for (var doc
                                              in collaborationSnapshot.docs) {
                                            await doc.reference.delete();
                                          }

                                          // Then delete the main todo
                                          await toDoService.deleteTodo(
                                            todoModel?.id ?? '',
                                          );
                                          statee(() {
                                            listToDoModel.removeAt(index);
                                            toDoList.remove(todoId);
                                          });
                                        } catch (e) {
                                          if (context.mounted) {
                                            SnackBarHelper.showErrorSnackBar(
                                                context, e.toString());
                                          }
                                        } finally {
                                          statee(() {
                                            isDeleting = false;
                                          });
                                          Navigator.of(context).pop(true);
                                        }
                                      },
                                      onCancel: () {
                                        Navigator.of(context).pop();
                                      });
                                }));
                        if (g == true) {
                          await _loadAndInitCategories();
                        }
                      },
                    ),
                  )
                ],
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

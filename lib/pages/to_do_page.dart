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
import 'package:four_secrets_wedding_app/services/email_service.dart';
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
import '../widgets/collaboration_todo_tile.dart';
import '../services/non_registered_invite_service.dart';
import '../models/non_registered_user.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final toDoService = TodoService();
  final authService = AuthService();
  final emailService = EmailService();
  final key = GlobalKey<MenueState>();
  final collaborationService = CollaborationService();
  bool isLoading = false;
  List<ToDoModel> listToDoModel = [];
  Map<String, dynamic> toDoList = {};
  List<String> selectedItems = [];
  String? selectedCategory;
  bool isDeleting = false;
  bool hasNewCollabNotification = false;
  int? _editingCommentIndex;
  TextEditingController _editingController = TextEditingController();
  TextEditingController _commentController = TextEditingController();
  // Unified comment edit state
  int? editingCommentIndex;
  Map<String, dynamic>? editingComment;
  bool isEditingComment = false;
  // User cache for comments
  final Map<String, Map<String, dynamic>> _userCache = {};
  String? currentlyInvitingEmail;

  @override
  void initState() {
    super.initState();
    _loadAndInitCategories();
    _checkUnreadNotifications();
    // _markAllCollabNotificationsAsRead();
  }

  Future<void> _loadAndInitCategories() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final myEmail = FirebaseAuth.instance.currentUser?.email;
      if (myUid == null || myEmail == null) return;
      // Fetch owned todos
      final ownedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('todos')
          .get();
      final ownedTodos = ownedSnapshot.docs
          .map((doc) => ToDoModel.fromFirestore(doc))
          .toList();
      print(
          '[ToDo Debug] Owned todos count: \x1B[32m[32m${ownedTodos.length}\x1B[0m');
      print(
          '[ToDo Debug] Owned todo IDs: ${ownedTodos.map((t) => t.id).toList()}');
      // Fetch shared todos (isShared == true and collaborators contains me, but not owned by me)
      final sharedSnapshot = await FirebaseFirestore.instance
          .collectionGroup('todos')
          .where('isShared', isEqualTo: true)
          .where('collaborators', arrayContains: myEmail)
          .get();
      final sharedTodos = sharedSnapshot.docs
          .where((doc) => doc.data()['userId'] != myUid)
          .map((doc) => ToDoModel.fromFirestore(doc))
          .toList();
      print(
          '[ToDo Debug] Shared todos count: \x1B[34m${sharedTodos.length}\x1B[0m');
      print(
          '[ToDo Debug] Shared todo IDs: ${sharedTodos.map((t) => t.id).toList()}');
      // Fetch revoked todos (revokedFor contains me, but not owned by me)
      final revokedSnapshot = await FirebaseFirestore.instance
          .collectionGroup('todos')
          .where('revokedFor', arrayContains: myEmail)
          .get();
      final revokedTodos = revokedSnapshot.docs
          .where((doc) => doc.data()['userId'] != myUid)
          .map((doc) => ToDoModel.fromFirestore(doc))
          .toList();
      print(
          '[ToDo Debug] Revoked todos count: \x1B[31m${revokedTodos.length}\x1B[0m');
      print(
          '[ToDo Debug] Revoked todo IDs: ${revokedTodos.map((t) => t.id).toList()}');
      // Combine owned, shared, and revoked, avoid duplicates
      final allTodos = <String, ToDoModel>{};
      for (final todo in [...ownedTodos, ...sharedTodos, ...revokedTodos]) {
        allTodos[todo.id ?? ''] = todo;
      }
      // Filter: only show todos where user is owner, collaborator, or revokedFor
      final filteredTodos = allTodos.values.where((todo) {
        final isOwner = todo.userId == myUid;
        final isCollaborator = todo.collaborators.contains(myEmail);
        final isRevoked = todo.revokedFor.contains(myEmail);
        return isOwner || isCollaborator || isRevoked;
      }).toList();
      print('[ToDo Debug] All todos count: ${filteredTodos.length}');
      print(
          '[ToDo Debug] All todo IDs: ${filteredTodos.map((t) => t.id).toList()}');
      setState(() {
        listToDoModel = filteredTodos;
        toDoList = Map.fromEntries(filteredTodos
            .map((todo) => MapEntry(todo.id ?? '', todo.toDoItems ?? [])));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
      SnackBarHelper.showErrorSnackBar(context, "Error loading todos: $e");
    }
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
    print("notifications");
    // Only set to true if there is an unread invitation notification
    final hasInvite = snapshot.docs
        .any((doc) => (doc.data()['data']?['type'] ?? '') == 'invitation');
    setState(() {
      hasNewCollabNotification = hasInvite;
      print(hasNewCollabNotification);
    });
  }

  Future<void> _showInviteDialog() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    bool isSendingInvite = false;
    String? inviteEmai;
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
                                  .where((user) =>
                                      user['email'] != currentUser?.email)
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
                    (!isSearching && searchResults.isNotEmpty)
                        ? Container(
                            constraints: BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final user = searchResults[index];
                                return ListTile(
                                  title: Text(user['name']),
                                  subtitle: Text(user['email']),
                                  trailing: (isSendingInvite &&
                                          currentlyInvitingEmail ==
                                              user['email'])
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
                                                  setState(() {
                                                    isSendingInvite = true;
                                                    currentlyInvitingEmail =
                                                        user['email'];
                                                  });
                                                  try {
                                                    await collaborationService
                                                        .sendInvitationForAllTodos(
                                                      inviteeEmail:
                                                          user['email'],
                                                      inviteeName: user['name'],
                                                    );
                                                    await emailService
                                                        .sendInvitationEmail(
                                                      email: user['email'],
                                                      inviterName: user['name'],
                                                    );

                                                    // Save to non_registered_users collection
                                                    final nonRegisteredUser =
                                                        NonRegisteredUser(
                                                      email: user['email'],
                                                      name: user['name'],
                                                      invitedAt: DateTime.now(),
                                                    );
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'non_registered_users')
                                                        .doc(nonRegisteredUser
                                                            .email)
                                                        .set(nonRegisteredUser
                                                            .toMap());
                                                    // Refresh the data before closing the dialog
                                                    await _loadAndInitCategories();
                                                    if (context.mounted) {
                                                      Navigator.of(context)
                                                          .pop();
                                                      SnackBarHelper
                                                          .showSuccessSnackBar(
                                                              context,
                                                              "Einladung für alle Listen gesendet");
                                                    }
                                                  } catch (e) {
                                                    print(e);
                                                    SnackBarHelper
                                                        .showErrorSnackBar(
                                                            context,
                                                            "Fehler beim Senden der Einladung: $e");
                                                  } finally {
                                                    if (mounted)
                                                      setState(() {
                                                        isSendingInvite = false;
                                                        currentlyInvitingEmail =
                                                            null;
                                                      });
                                                  }
                                                },
                                        ),
                                );
                              },
                            ),
                          )
                        : (!isSearching &&
                                searchController.text.isNotEmpty &&
                                searchResults.isEmpty)
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 10),
                                child: Row(
                                  children: [
                                    // E‑Mail-Text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            searchController.text,
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black),
                                          ),
                                          Text(
                                            "Einladen",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Lade-Indikator oder Invite-Button
                                    isSendingInvite
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.person_add,
                                                color: Color.fromARGB(
                                                    255, 107, 69, 106)),
                                            onPressed: () async {
                                              setState(
                                                  () => isSendingInvite = true);
                                              final name = searchController.text
                                                  .split('@')
                                                  .first;
                                              try {
                                                await collaborationService
                                                    .sendInvitationForAllTodos(
                                                  inviteeEmail:
                                                      searchController.text,
                                                  inviteeName:
                                                      name[0].toUpperCase() +
                                                          name.substring(1),
                                                );
                                                await emailService
                                                    .sendInvitationEmail(
                                                  email: searchController.text,
                                                  inviterName:
                                                      name[0].toUpperCase() +
                                                          name.substring(1),
                                                );
                                                // Save to non_registered_users collection
                                                final nonRegisteredUser =
                                                    NonRegisteredUser(
                                                  email: searchController.text,
                                                  name: name[0].toUpperCase() +
                                                      name.substring(1),
                                                  invitedAt: DateTime.now(),
                                                );
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                        'non_registered_users')
                                                    .doc(
                                                        nonRegisteredUser.email)
                                                    .set(nonRegisteredUser
                                                        .toMap());
                                                await _loadAndInitCategories();
                                                if (context.mounted) {
                                                  Navigator.of(context).pop();
                                                  SnackBarHelper
                                                      .showSuccessSnackBar(
                                                          context,
                                                          "Einladung gesendet");
                                                }
                                              } catch (e) {
                                                SnackBarHelper
                                                    .showErrorSnackBar(
                                                        context, "Fehler: $e");
                                              } finally {
                                                if (mounted)
                                                  setState(() =>
                                                      isSendingInvite = false);
                                              }
                                            },
                                          ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
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

  String formatCommentTimestamp(dynamic ts) {
    if (ts == null) return '';
    DateTime dateTime;
    if (ts is DateTime) {
      dateTime = ts;
    } else if (ts is String) {
      dateTime = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      dateTime = DateTime.now();
    }
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return 'vor ${diff.inDays} Tagen';
    } else if (diff.inHours > 0) {
      return 'vor ${diff.inHours} Stunden';
    } else if (diff.inMinutes > 0) {
      return 'vor ${diff.inMinutes} Minuten';
    } else {
      return 'Gerade eben';
    }
  }

  // Add this helper for the invitation notification stream
  Stream<bool> get _hasNewCollabNotificationStream async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield false;
      return;
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final userEmail = user.email;
    if (fcmToken == null && userEmail == null) {
      yield false;
      return;
    }
    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.any((doc) {
        final data = doc.data();
        final type = data['data']?['type'] ?? '';
        final tokenMatch = fcmToken != null && data['token'] == fcmToken;
        final emailMatch =
            userEmail != null && data['data']?['toEmail'] == userEmail;
        return (type == 'invitation' || type == 'comment') &&
            (tokenMatch || emailMatch);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myEmail = FirebaseAuth.instance.currentUser?.email;
    return SafeArea(
        child: Scaffold(
            drawer: Menue.getInstance(key),
            appBar: AppBar(
              foregroundColor: Colors.white,
              title: const Text(AppConstants.toDoPageTitle),
              backgroundColor: const Color.fromARGB(255, 107, 69, 106),
              actions: [
                StreamBuilder<bool>(
                  stream: _hasNewCollabNotificationStream,
                  initialData: false,
                  builder: (context, snapshot) {
                    final hasNewCollabNotification = snapshot.data ?? false;
                    return Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.group),
                          tooltip: 'Zusammenarbeit',
                          onPressed: () async {
                            // Optionally mark as read here if you want
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CollaborationScreen()),
                            );

                            await _loadAndInitCategories();
                            setState(() {});
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
                    );
                  },
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
                if (listToDoModel.any((todo) =>
                    (((todo as dynamic).ownerEmail != null &&
                            (todo as dynamic).ownerEmail ==
                                FirebaseAuth.instance.currentUser?.email) ||
                        (todo.userId ==
                            FirebaseAuth.instance.currentUser?.uid)) &&
                    todo.collaborators.isNotEmpty &&
                    (todo.revokedFor.isEmpty ||
                        !todo.revokedFor.contains(
                            FirebaseAuth.instance.currentUser?.email))))
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    tooltip: 'Zugriff entziehen',
                    onPressed: () async {
                      final myUid = FirebaseAuth.instance.currentUser?.uid;
                      // Only allow for owners
                      final ownedTodos = listToDoModel
                          .where((todo) =>
                              (((todo as dynamic).ownerEmail != null &&
                                      (todo as dynamic).ownerEmail ==
                                          FirebaseAuth
                                              .instance.currentUser?.email) ||
                                  (todo.userId == myUid)) &&
                              (todo.collaborators.isNotEmpty))
                          .toList();
                      if (ownedTodos.isEmpty) {
                        SnackBarHelper.showErrorSnackBar(context,
                            'Keine geteilten Listen zum Entziehen gefunden.');
                        return;
                      }
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => CustomDialog(
                          title: 'Zugriff entziehen',
                          message:
                              'Möchten Sie den Zugriff für alle Mitwirkenden auf alle geteilten Listen entziehen?',
                          confirmText: 'Entziehen',
                          cancelText: 'Abbrechen',
                          onConfirm: () => Navigator.pop(context, true),
                          onCancel: () => Navigator.pop(context, false),
                        ),
                      );
                      if (confirm == true) {
                        try {
                          for (final todo in ownedTodos) {
                            await toDoService.removeAllCollaborators(todo.id!);
                            final userQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('email', isEqualTo: todo.ownerEmail)
                                .limit(1)
                                .get();
                            String? ownerUid;
                            if (userQuery.docs.isNotEmpty) {
                              ownerUid = userQuery.docs.first.id;
                            } else {
                              // fallback: use email as UID (legacy)
                              ownerUid = todo.ownerEmail;
                            }
                            final doc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(ownerUid)
                                .get();
                            final name = doc.data()?['name'] ?? todo.ownerEmail;

                            print(name);
                            if (todo.ownerEmail != null) {
                              await emailService.sendRevokeAccessEmail(
                                email: todo.ownerEmail!,
                                inviterName: name,
                              );
                            }
                          }
                          SnackBarHelper.showSuccessSnackBar(
                              context, 'Zugriff erfolgreich entzogen.');
                          await _loadAndInitCategories();
                        } catch (e) {
                          SnackBarHelper.showErrorSnackBar(
                              context, 'Fehler: $e');
                        }
                      }
                    },
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
                    var g = await Navigator.pushNamed(
                      context,
                      RouteManager.addToDoPage,
                      arguments: {
                        "toDoModel": null,
                        "id": null,
                        "showOnlyCustomCategories": true,
                      },
                    );
                    if (g == true) {
                      _loadAndInitCategories();
                    }
                  },
                ),
              ],
            ),
            body: ListView(children: [
              Image.asset("assets/images/background/todoBg.jpeg"),
              SpacerWidget(height: 5),
              FourSecretsDivider(),
              // Always show accepted/collaborated section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    // FourSecretsDivider(),
                    ...toDoList.entries.map((entry) {
                      String todoId = entry.key;
                      ToDoModel? todoModel;
                      for (final todo in listToDoModel) {
                        if ((todo.id ?? '') == todoId) {
                          todoModel = todo;
                          break;
                        }
                      }
                      if (todoModel == null) return SizedBox();
                      String toDoName = todoModel.toDoName ?? '';
                      String displayName = toDoName.isNotEmpty
                          ? toDoName
                          : (todoModel.categories != null &&
                                  todoModel.categories!.isNotEmpty &&
                                  (todoModel.categories![0]['categoryName']
                                          ?.toString()
                                          .isNotEmpty ??
                                      false)
                              ? todoModel.categories![0]['categoryName']
                              : '');
                      List<Map<String, dynamic>> itemsToDo =
                          todoModel.toDoItems ?? [];
                      int index =
                          listToDoModel.indexWhere((todo) => todo.id == todoId);
                      if (index == -1) index = 0;
                      final isOwner = todoModel?.userId == myUid;
                      final isCollaborator =
                          todoModel?.collaborators.contains(myEmail) ?? false;
                      final canComment = isOwner || isCollaborator;
                      // Use correct collectionPath for owned or shared todos
                      final collectionPath = isOwner
                          ? 'users/$myUid/todos'
                          : 'users/${todoModel?.userId}/todos';
                      // Show tag: 'Owned' for owner, 'Shared by' for collaborator
                      return CollaborationTodoTile(
                        collabId: todoModel.id ?? '',
                        color: Colors.grey.withAlpha(30),
                        labelColor:
                            Color.fromARGB(255, 107, 69, 106).withAlpha(200),
                        labelTextColor: Colors.white,
                        checkboxColor: Color.fromARGB(255, 107, 69, 106),
                        avatarColor:
                            Color.fromARGB(255, 107, 69, 106).withAlpha(100),
                        collectionPath: collectionPath,
                        showTag: isOwner || isCollaborator,
                      );
                    }).toList(),
                    SpacerWidget(height: 1),
                    listToDoModel.isEmpty
                        ? AbsorbPointer()
                        : FourSecretsDivider(),
                    SpacerWidget(height: 10),
                  ],
                ),
              )
            ])));
  }
}

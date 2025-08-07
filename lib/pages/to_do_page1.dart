import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';
import 'package:four_secrets_wedding_app/pages/collaboration_screen.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/auth_service.dart';
import 'package:four_secrets_wedding_app/services/collaboration_service.dart';
import 'package:four_secrets_wedding_app/services/email_service.dart';
import 'package:four_secrets_wedding_app/services/push_notification_service.dart';
import 'package:four_secrets_wedding_app/services/todo_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/services/todo_unread_status_service.dart';

import '../models/non_registered_user.dart';
import '../widgets/collaboration_todo_tile.dart';

class ToDoPage1 extends StatefulWidget {
  const ToDoPage1({super.key});

  @override
  State<ToDoPage1> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage1> {
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
  // int? _editingCommentIndex;
  // TextEditingController _editingController = TextEditingController();
  // TextEditingController _commentController = TextEditingController();
  // Unified comment edit state
  int? editingCommentIndex;
  Map<String, dynamic>? editingComment;
  bool isEditingComment = false;
  // User cache for comments
  // final Map<String, Map<String, dynamic>> _userCache = {};
  String? currentlyInvitingEmail;

  @override
  void initState() {
    super.initState();
    _loadAndInitCategories();
    _checkUnreadNotifications();
    // _markAllCollabNotificationsAsRead();
  }

  Future<void> _loadAndInitCategories() async {
    print(
        '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: _loadAndInitCategories started');
    if (!mounted) {
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Widget not mounted, returning');
      return;
    }
    print(
        '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Setting isLoading = true');
    setState(() {
      isLoading = true;
    });
    print(
        '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: isLoading setState completed');
    try {
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Getting current user info');
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final myEmail = FirebaseAuth.instance.currentUser?.email;
      if (myUid == null || myEmail == null) {
        print(
            '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: User not authenticated, returning');
        return;
      }
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: User authenticated, fetching owned todos');
      // Fetch owned todos
      final ownedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('todos')
          .get();
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Owned todos query completed');
      final ownedTodos = ownedSnapshot.docs
          .map((doc) => ToDoModel.fromFirestore(doc))
          .toList();
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Owned todos mapped to models');
      print(
          '[ToDo Debug] Owned todos count: \x1B[32m[32m${ownedTodos.length}\x1B[0m');
      print(
          '[ToDo Debug] Owned todo IDs: ${ownedTodos.map((t) => t.id).toList()}');
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting shared todos query');
      // NEW LOGIC: Fetch shared todos based on accepted invitations
      print('[SHARED_DEBUG] Querying accepted invitations for email: $myEmail');
      final acceptedInvitationsSnapshot = await FirebaseFirestore.instance
          .collection('invitations')
          .where('inviteeEmail', isEqualTo: myEmail)
          .where('status', isEqualTo: 'accepted')
          .get();

      print(
          '[SHARED_DEBUG] Found ${acceptedInvitationsSnapshot.docs.length} accepted invitations');

      // [ACCEPTED_INVITATIONS_LOG] Print all accepted invitations details
      print(
          '[ACCEPTED_INVITATIONS_LOG] ===== ALL ACCEPTED INVITATIONS FOR USER: $myEmail =====');
      for (int i = 0; i < acceptedInvitationsSnapshot.docs.length; i++) {
        final doc = acceptedInvitationsSnapshot.docs[i];
        final data = doc.data();
        print('[ACCEPTED_INVITATIONS_LOG] Invitation ${i + 1}:');
        print('[ACCEPTED_INVITATIONS_LOG]   - ID: ${doc.id}');
        print(
            '[ACCEPTED_INVITATIONS_LOG]   - Inviter Email: ${data['inviterEmail']}');
        print(
            '[ACCEPTED_INVITATIONS_LOG]   - Inviter Name: ${data['inviterName']}');
        print(
            '[ACCEPTED_INVITATIONS_LOG]   - Invitee Email: ${data['inviteeEmail']}');
        print(
            '[ACCEPTED_INVITATIONS_LOG]   - Invitee Name: ${data['inviteeName']}');
        print('[ACCEPTED_INVITATIONS_LOG]   - Status: ${data['status']}');
        print(
            '[ACCEPTED_INVITATIONS_LOG]   - Created At: ${data['createdAt']}');
        print(
            '[ACCEPTED_INVITATIONS_LOG]   - Responded At: ${data['respondedAt']}');
        print(
            '[ACCEPTED_INVITATIONS_LOG]   - Todo Count: ${data['todoCount']}');
        print('[ACCEPTED_INVITATIONS_LOG]   - Todo IDs: ${data['todoIds']}');
        print(
            '[ACCEPTED_INVITATIONS_LOG]   - Todo Names: ${data['todoNames']}');
        print('[ACCEPTED_INVITATIONS_LOG]   ---');
      }
      print('[ACCEPTED_INVITATIONS_LOG] ===== END ACCEPTED INVITATIONS =====');

      List<ToDoModel> sharedTodos = [];

      // For each accepted invitation, fetch all todos from the inviter
      for (var invitationDoc in acceptedInvitationsSnapshot.docs) {
        final invitationData = invitationDoc.data();
        final inviterEmail = invitationData['inviterEmail'];

        print('[SHARED_DEBUG] Processing invitation from: $inviterEmail');

        // Find inviter's user ID by email
        final inviterQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: inviterEmail)
            .limit(1)
            .get();

        if (inviterQuery.docs.isNotEmpty) {
          final inviterId = inviterQuery.docs.first.id;
          print('[SHARED_DEBUG] Found inviter ID: $inviterId');

          // Fetch ALL todos from this inviter
          final inviterTodosSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(inviterId)
              .collection('todos')
              .get();

          print(
              '[SHARED_DEBUG] Found ${inviterTodosSnapshot.docs.length} todos from inviter');

          // Add all inviter's todos to shared list
          for (var todoDoc in inviterTodosSnapshot.docs) {
            try {
              final todo = ToDoModel.fromFirestore(todoDoc);
              sharedTodos.add(todo);
              print(
                  '[SHARED_DEBUG] Added shared todo: ${todo.id} - ${todo.toDoName}');
            } catch (e) {
              print('[SHARED_DEBUG] Error parsing todo ${todoDoc.id}: $e');
            }
          }
        } else {
          print('[SHARED_DEBUG] Inviter not found for email: $inviterEmail');
        }
      }

      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Shared todos loaded via invitations');
      print('[ToDo Debug] Shared todos count: ${sharedTodos.length}');
      print(
          '[ToDo Debug] Shared todo IDs: ${sharedTodos.map((t) => t.id).toList()}');
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting todos combination and filtering');
      // Combine owned and shared todos, avoid duplicates
      final allTodos = <String, ToDoModel>{};
      for (final todo in [...ownedTodos, ...sharedTodos]) {
        allTodos[todo.id ?? ''] = todo;
      }
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Todos combined, starting filtering');
      // Simple filter: show all owned and shared todos (no revoked logic needed)
      final filteredTodos = allTodos.values.toList();
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Filtering completed');
      print('[ToDo Debug] All todos count: ${filteredTodos.length}');
      print(
          '[ToDo Debug] All todo IDs: ${filteredTodos.map((t) => t.id).toList()}');
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting final setState');
      setState(() {
        listToDoModel = filteredTodos;
        toDoList = Map.fromEntries(filteredTodos
            .map((todo) => MapEntry(todo.id ?? '', todo.toDoItems ?? [])));
        isLoading = false;
      });
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Final setState completed - _loadAndInitCategories finished successfully');
    } catch (e) {
      print(
          '[LOAD_LOG] ${DateTime.now().millisecondsSinceEpoch}: Error in _loadAndInitCategories: $e');
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

  /// Validates email format using regex
  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Email regex pattern
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    return emailRegex.hasMatch(email);
  }

  Future<void> _showInviteDialog() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    bool isSendingInvite = false;
    String? currentlyInvitingEmail;
    Set<String> sentInvitations = {}; // Track successfully sent invitations
    String? inviteEmai;
    String? errorMessage; // Add error message state
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
                          hintText:
                              "E-Mail-Adresse für Zusammenarbeit eingeben...",
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
                              setState(() {
                                isSearching = false;
                                errorMessage = "Fehler bei der Suche: $e";
                              });
                            }
                          } else {
                            setState(() => searchResults = []);
                            // isSearching = false;
                          }
                        },
                      ),
                    ),
                    // Error message display
                    if (errorMessage != null)
                      Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.red, size: 18),
                              onPressed: () {
                                setState(() {
                                  errorMessage = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
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
                                  trailing: sentInvitations
                                          .contains(user['email'])
                                      ? Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Gesendet',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : (isSendingInvite &&
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
                                                      print(
                                                          '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting setState for isSendingInvite = true');
                                                      setState(() {
                                                        isSendingInvite = true;
                                                        currentlyInvitingEmail =
                                                            user['email'];
                                                      });
                                                      print(
                                                          '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: setState completed for isSendingInvite = true');
                                                      try {
                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting sendInvitationForAllTodos');
                                                        // Send main invitation (this is the critical part)
                                                        await collaborationService
                                                            .sendInvitationForAllTodos(
                                                          inviteeEmail:
                                                              user['email'],
                                                          inviteeName:
                                                              user['name'],
                                                        );
                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: sendInvitationForAllTodos completed');

                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Invitation sent to registered user - todoUnreadStatus handled by collaboration service');
                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Firestore save completed');

                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting email notification');
                                                        // Try to send email notification (but don't fail if this fails)
                                                        try {
                                                          emailService
                                                              .sendInvitationEmail(
                                                            email:
                                                                user['email'],
                                                            inviterName:
                                                                user['name'],
                                                          );
                                                          print(
                                                              '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Email notification sent successfully');
                                                        } catch (emailError) {
                                                          print(
                                                              '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Email sending failed but invitation was successful: $emailError');
                                                        }

                                                        // Refresh the data

                                                        // Reset loader state and mark as sent
                                                        if (mounted) {
                                                          setState(() {
                                                            isSendingInvite =
                                                                false;
                                                            currentlyInvitingEmail =
                                                                null;
                                                            sentInvitations.add(
                                                                user['email']);
                                                          });

                                                          // Show green success snackbar
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  '✓ Einladung für alle Listen gesendet'),
                                                              backgroundColor:
                                                                  Colors.green,
                                                              duration:
                                                                  Duration(
                                                                      seconds:
                                                                          2),
                                                            ),
                                                          );
                                                          if (mounted) {
                                                            print(
                                                                '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting _loadAndInitCategories');
                                                            await _loadAndInitCategories();
                                                            print(
                                                                '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: _loadAndInitCategories completed');

                                                            print(
                                                                '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Popping dialog');
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            print(
                                                                '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Dialog popped successfully');
                                                          }
                                                        }
                                                      } catch (e) {
                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Main invitation failed: $e');
                                                        // if (mounted) {
                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting error setState');
                                                        setState(() {
                                                          isSendingInvite =
                                                              false;
                                                          currentlyInvitingEmail =
                                                              null;
                                                          errorMessage =
                                                              "Fehler beim Senden der Einladung: $e";
                                                        });
                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Error setState completed');
                                                        print(
                                                            '[INVITE_LOG] ${DateTime.now().millisecondsSinceEpoch}: Error message set in dialog');
                                                        // }
                                                      }

                                                      setState(() {
                                                        isSendingInvite = false;
                                                        currentlyInvitingEmail =
                                                            null;
                                                      });
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
                                    // Success message, loader, or invite button
                                    sentInvitations
                                            .contains(searchController.text)
                                        ? Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Gesendet',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : isSendingInvite
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : IconButton(
                                                icon: Icon(Icons.person_add,
                                                    color: Color.fromARGB(
                                                        255, 107, 69, 106)),
                                                onPressed: () async {
                                                  // Validate email before sending
                                                  final email = searchController
                                                      .text
                                                      .trim();
                                                  if (!_isValidEmail(email)) {
                                                    setState(() {
                                                      errorMessage =
                                                          "Ungültige E-Mail-Adresse";
                                                    });
                                                    return;
                                                  }

                                                  // Clear any previous error messages
                                                  setState(() {
                                                    errorMessage = null;
                                                  });

                                                  setState(() =>
                                                      isSendingInvite = true);
                                                  final name =
                                                      email.split('@').first;
                                                  try {
                                                    final userName =
                                                        name[0].toUpperCase() +
                                                            name.substring(1);

                                                    // Send main invitation (this is the critical part)
                                                    await collaborationService
                                                        .sendInvitationForAllTodos(
                                                      inviteeEmail: email,
                                                      inviteeName: userName,
                                                    );

                                                    // Save to non_registered_users collection
                                                    final nonRegisteredUser =
                                                        NonRegisteredUser(
                                                      email: email,
                                                      name: userName,
                                                      invitedAt: DateTime.now(),
                                                      todoUnreadStatus:
                                                          true, // Set to true when inviting
                                                    );
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'non_registered_users')
                                                        .doc(nonRegisteredUser
                                                            .email)
                                                        .set(nonRegisteredUser
                                                            .toMap());

                                                    // Try to send email notification (but don't fail if this fails)
                                                    try {
                                                      emailService
                                                          .sendInvitationEmail(
                                                        email: email,
                                                        inviterName: userName,
                                                      );
                                                    } catch (emailError) {
                                                      print(
                                                          'Email sending failed but invitation was successful: $emailError');
                                                    }

                                                    // Refresh the data

                                                    // Reset loader state and mark as sent
                                                    // if (mounted) {
                                                    setState(() {
                                                      isSendingInvite = false;
                                                      sentInvitations
                                                          .add(email);
                                                    });

                                                    // Show green success snackbar
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            '✓ Einladung gesendet'),
                                                        backgroundColor:
                                                            Colors.green,
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );

                                                    _loadAndInitCategories();
                                                    // Close dialog after showing success message
                                                    Future.delayed(
                                                        Duration(
                                                            milliseconds: 500),
                                                        () {
                                                      if (mounted &&
                                                          Navigator.canPop(
                                                              context)) {
                                                        Navigator.of(context)
                                                            .pop();
                                                      }
                                                    });
                                                    // }
                                                  } catch (e) {
                                                    print(
                                                        'Main invitation failed: $e');
                                                    // if (mounted) {
                                                    setState(() {
                                                      isSendingInvite = false;
                                                      errorMessage =
                                                          "Fehler: ${e.toString().replaceAll('Exception:', '')}";
                                                    });
                                                    // }
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
                          hintText: "Kategorie Name eingeben...",
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

  // Use shared notification stream from PushNotificationService
  Stream<bool> get _hasNewCollabNotificationStream =>
      PushNotificationService.hasNewCollabNotificationStream;

  var hideItem = true;

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myEmail = FirebaseAuth.instance.currentUser?.email;
    return SafeArea(
        child: Scaffold(
            drawer: Menue.getInstance(key),
            onDrawerChanged: (isOpened) {
              if (isOpened) {
                // Dismiss keyboard when drawer is opened
                FocusScope.of(context).unfocus();
              }
            },
            appBar: AppBar(
              foregroundColor: Colors.white,
              title: const Text(AppConstants.toDoPageTitle),
              backgroundColor: const Color.fromARGB(255, 107, 69, 106),
              actions: [
                StreamBuilder<bool>(
                  stream: TodoUnreadStatusService
                      .getCurrentUserUnreadStatusStream(),
                  initialData: false,
                  builder: (context, snapshot) {
                    final hasUnreadTodos = snapshot.data ?? false;
                    return Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.group),
                          tooltip: 'Zusammenarbeit',
                          onPressed: () async {
                            // Mark as read when user clicks the collaboration icon
                            if (hasUnreadTodos) {
                              await TodoUnreadStatusService
                                  .markAsReadForCurrentUser();
                            }

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CollaborationScreen()),
                            );

                            await _loadAndInitCategories();
                            setState(() {});
                          },
                        ),
                        if (hasUnreadTodos)
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
                  if (hideItem == false)
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
                              await toDoService
                                  .removeAllCollaborators(todo.id!);
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
                              final name =
                                  doc.data()?['name'] ?? todo.ownerEmail;

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
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Center(
                                child: CustomTextWidget(
                                    textAlign: TextAlign.center,
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    text:
                                        "Noch Keine Punkte hinzugefügt. Tippe auf das + Symbol unten rechts.")),
                          ),
                          FourSecretsDivider(),
                        ],
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
                      final isOwner = todoModel.userId == myUid;
                      // NEW LOGIC: For invitation-based system, if todo is in our shared list, we can interact
                      final isSharedWithMe =
                          !isOwner; // If not owner and in our list, it's shared with us
                      final canComment = isOwner || isSharedWithMe;
                      final canEdit = isOwner || isSharedWithMe;
                      // Use correct collectionPath for owned or shared todos
                      final collectionPath = isOwner
                          ? 'users/$myUid/todos'
                          : 'users/${todoModel.userId}/todos';
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
                        showTag: isOwner || isSharedWithMe,
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

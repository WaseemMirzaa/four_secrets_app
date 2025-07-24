import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';
import 'package:four_secrets_wedding_app/services/collaboration_service.dart';
import 'package:four_secrets_wedding_app/services/email_service.dart';
import 'package:four_secrets_wedding_app/services/todo_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';

import '../services/push_notification_service.dart';
import '../widgets/custom_button_widget.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({Key? key}) : super(key: key);

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen>
    with SingleTickerProviderStateMixin {
  final key = GlobalKey<MenueState>();

  final Set<String> _acceptingInvites =
      {}; // Track loading state for accepting invites
  List<Map<String, dynamic>>? pendingInvitations;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _cancellingInvites =
      {}; // Track loading state for cancelling invites

  List<ToDoModel> _collaboratedTodos = [];
  final CollaborationService _collaborationService = CollaborationService();
  final TextEditingController _commentController = TextEditingController();
  final EmailService _emailService = EmailService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<ToDoModel> _ownedTodos = [];
  final PushNotificationService _pushNotificationService =
      PushNotificationService();

  List<Map<String, dynamic>> _receivedInvitations = [];
  List<Map<String, dynamic>> _sentInvitations = [];
  late TabController _tabController;
  final TodoService _todoService = TodoService();
  Map<String, Map<String, String>> _userCache = {};

  @override
  void dispose() {
    _commentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  // Use shared notification stream from PushNotificationService
  Stream<bool> get _hasNewCollabNotificationStream =>
      PushNotificationService.hasNewCollabNotificationStream;

  Future<void> _loadData() async {
    // if (!mounted) return;
    print(
        '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: _loadData started');
    setState(() => _isLoading = true);
    try {
      final myEmail = _auth.currentUser?.email;
      if (myEmail == null) {
        print(
            '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: No user email, returning');
        return;
      }
      // Load sent invitations
      final sentSnapshot = await _firestore
          .collection('invitations')
          .where('inviterEmail', isEqualTo: myEmail)
          .get();
      _sentInvitations = sentSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
      // Load received invitations
      final receivedSnapshot = await _firestore
          .collection('invitations')
          .where('inviteeEmail', isEqualTo: myEmail)
          .get();
      _receivedInvitations = receivedSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id, 'isNonRegistered': false})
          .toList();
      // Load owned todos
      final myUid = _auth.currentUser?.uid;
      final ownedSnapshot = await _firestore
          .collection('users')
          .doc(myUid)
          .collection('todos')
          .get();
      _ownedTodos = ownedSnapshot.docs
          .map((doc) => ToDoModel.fromFirestore(doc))
          .toList();
      // Load collaborated todos (shared with me)
      final collaboratedSnapshot = await _firestore
          .collectionGroup('todos')
          .where('collaborators', arrayContains: myEmail)
          .get();
      _collaboratedTodos = collaboratedSnapshot.docs
          .where((doc) => doc.data()['userId'] != myUid)
          .map((doc) => ToDoModel.fromFirestore(doc))
          .toList();
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Loading sent invitations: ${_sentInvitations.length}');
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Loading received invitations: ${_receivedInvitations.length}');

      final inviterEmails = _receivedInvitations
          .map((invite) => invite['inviterEmail'])
          .whereType<String>()
          .toSet();
      await _preloadUserInfo(inviterEmails);

      // if (mounted) {
      setState(() => _isLoading = false);
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: _loadData completed successfully');
      // }
    } catch (e) {
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Error in _loadData: $e');
      // if (mounted) {
      setState(() => _isLoading = false);
      SnackBarHelper.showErrorSnackBar(
          context, "Error loading collaboration data: $e");
      // }
    }
  }

  Future<void> _preloadUserInfo(Set<String> userIds) async {
    for (final userId in userIds) {
      if (!_userCache.containsKey(userId)) {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data()!;
          _userCache[userId] = {
            'name': data['name'] ?? 'Unknown',
            'email': data['email'] ?? '',
          };
        } else {
          _userCache[userId] = {
            'name': 'Unknown',
            'email': '',
          };
        }
      }
    }
  }

  // Use shared notification service method
  Future<void> _markAllCollabNotificationsAsRead() async {
    await PushNotificationService.markAllCollabNotificationsAsRead();
  }

  // Future<void> _respondToInvitation(String invitationId, bool accept) async {
  //   // Find the invite in the received invitations
  //   final invite = _receivedInvitations.firstWhere(
  //     (element) => element['id'] == invitationId,
  //     orElse: () => {},
  //   );
  //   final isNonRegistered = invite['isNonRegistered'] == true;
  //   if (accept) {
  //     setState(() {
  //       _acceptingInvites.add(invitationId);
  //     });
  //   }
  //   try {
  //     if (isNonRegistered) {
  //       // Accept the non-registered invite
  //       await _collaborationService.respondToInvitationForAllTodos(
  //           invitationId, accept);
  //     } else if (invite.containsKey('todoIds')) {
  //       // Multi-todo invite
  //       await _collaborationService.respondToInvitationForAllTodos(
  //           invitationId, accept);
  //     } else if (invite.containsKey('todoId')) {
  //       // Single-todo invite
  //       await _collaborationService.respondToInvitation(invitationId, accept);
  //       // await _pushNotificationService.sendInvitationAcceptedNotification(inviterId: inviterId, inviteeName: inviteeName, todoName: todoName)
  //     } else {
  //       throw Exception('Invalid invitation format');
  //     }
  //     await _loadData();
  //     if (mounted) {
  //       SnackBarHelper.showSuccessSnackBar(
  //         context,
  //         accept ? 'Einladung akzeptiert' : 'Einladung abgelehnt',
  //       );
  //       if (accept) {
  //         Future.delayed(const Duration(milliseconds: 500), () {
  //           if (Navigator.of(context).canPop()) {
  //             Navigator.of(context).pop();
  //           }
  //         });
  //       } else {
  //         // await _pushNotificationService.sendInvitationRejectedNotification(
  //         //   inviterId: invite['inviterId'],
  //         //   inviteeName: invite['inviterName'],
  //         // );
  //         final currentUser = _auth.currentUser;
  //         final currentUserName = currentUser?.displayName ??
  //             currentUser?.email?.split('@').first ??
  //             'Jemand';

  //         await _pushNotificationService.sendInvitationRejectedNotification(
  //           inviterId: invite['inviterId'],
  //           inviteeName:
  //               currentUserName, // Now using the correct name of who is rejecting
  //         );
  //         print(
  //             'Sending rejection notification to inviter: ${invite['inviterId']}');
  //         print('Current user name: $currentUserName');
  //         print("Rejected");
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       SnackBarHelper.showErrorSnackBar(
  //         context,
  //         'Fehler beim Antworten auf die Einladung: $e',
  //       );
  //     }
  //   } finally {
  //     if (accept) {
  //       setState(() {
  //         _acceptingInvites.remove(invitationId);
  //       });
  //     }
  //   }
  // }
  Future<void> _respondToInvitation(String invitationId, bool accept) async {
    print('🔵 [DEBUG] Processing invitation $invitationId, accept: $accept');
    print(
        '🔵 [DEBUG] Total received invitations: ${_receivedInvitations.length}');
    print('🔵 [DEBUG] All received invitations: $_receivedInvitations');

    final invite = _receivedInvitations.firstWhere(
      (element) => element['id'] == invitationId,
      orElse: () => {},
    );

    print('🔵 [DEBUG] Found invite data: ${invite.toString()}');
    print('🔵 [DEBUG] Invite keys: ${invite.keys.toList()}');

    if (invite.isEmpty) {
      print('[ERROR] No invitation found');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Einladung nicht gefunden',
        );
      }
      return;
    }

    final isNonRegistered = invite['isNonRegistered'] == true;
    if (accept) {
      setState(() => _acceptingInvites.add(invitationId));
    }

    try {
      // Handle all invitation types
      if (isNonRegistered ||
          invite.containsKey('todoIds') ||
          invite.containsKey('todoId')) {
        print('🔵 [DEBUG] Calling respondToInvitationForAllTodos');
        await _collaborationService.respondToInvitationForAllTodos(
            invitationId, accept);
      } else {
        // Default case - don't throw exception
        print('🔵 [DEBUG] Calling basic respondToInvitation');
        await _collaborationService.respondToInvitation(invitationId, accept);
      }

      await _loadData();

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          accept ? 'Einladung akzeptiert' : 'Einladung abgelehnt',
        );

        // Send notification when rejecting
        if (!accept) {
          print('[DEBUG] Preparing rejection notification');
          final currentUser = _auth.currentUser;
          final currentUserName = currentUser?.displayName ??
              currentUser?.email?.split('@').first ??
              'Jemand';

          // Try to get inviterId from multiple possible sources
          String? inviterId;

          // 1. First try direct invitation field
          inviterId = invite['inviterId'];

          // 2. If not found, try to get from first todo's ownerId
          if (inviterId == null &&
              invite['todoIds'] != null &&
              invite['todoIds'].isNotEmpty) {
            try {
              final todoId = invite['todoIds'][0];
              final todoDoc = await _firestore
                  .collection('users')
                  .doc(invite['inviterId'] ?? invite['ownerId'])
                  .collection('todos')
                  .doc(todoId)
                  .get();

              if (todoDoc.exists) {
                inviterId = todoDoc.data()?['ownerId'];
              }
            } catch (e) {
              print('[ERROR] Failed to get todo owner: $e');
            }
          }

          // 3. If still not found, try to lookup by email
          if (inviterId == null && invite['inviterEmail'] != null) {
            try {
              final users = await _firestore
                  .collection('users')
                  .where('email', isEqualTo: invite['inviterEmail'])
                  .limit(1)
                  .get();

              if (users.docs.isNotEmpty) {
                inviterId = users.docs.first.id;
              }
            } catch (e) {
              print('[ERROR] Failed to lookup user by email: $e');
            }
          }

          if (inviterId == null) {
            print('[ERROR] Could not determine inviterId for notification');
            if (mounted) {
              SnackBarHelper.showErrorSnackBar(
                context,
                'Could not identify sender for notification',
              );
            }
          } else {
            await _pushNotificationService.sendInvitationRejectedNotification(
              inviterId: inviterId,
              inviteeName: currentUserName,
            );
            print('[DEBUG] Sent rejection notification to $inviterId');
          }
        }
        if (accept) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      print('[ERROR] In invitation response: $e');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Fehler: ${e.toString()}',
        );
      }
    } finally {
      if (accept) {
        setState(() => _acceptingInvites.remove(invitationId));
      }
    }
  }

  Future<void> _cancelInvitation(
      String invitationId, Map<String, dynamic> invite) async {
    print(
        '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Starting _cancelInvitation for ID: $invitationId');
    // setState(() {
    //   _cancellingInvites.add(invitationId);
    // });
    try {
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Calling deleteInvitation service');
      // Use the service method to handle deletion and notification
      await _collaborationService.deleteInvitation(invitationId);
      setState(() {
        pendingInvitations!.remove(invite);
      });
      // print(
      //     '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: deleteInvitation completed, reloading data');
      // setState(() {
      //   _cancellingInvites.remove(invitationId);
      // });
      // // Reload data to refresh the list
      // await _loadData();
      // print(
      //     '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Data reloaded after deletion');

      // if (mounted) {
      setState(() {
        _cancellingInvites.remove(invitationId);
      });
      SnackBarHelper.showSuccessSnackBar(
        context,
        'Die Einladung wurde storniert.',
      );
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Success snackbar shown');
      // }
    } catch (e) {
      setState(() {
        pendingInvitations!.remove(invite);
      });
      // The invitation was canceled.
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Error in _cancelInvitation: $e');
      if (mounted) {
        //   SnackBarHelper.showErrorSnackBar(
        //     context,
        //     'Fehler beim Stornieren der Einladung: $e',
        //   );
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Die Einladung wurde storniert.',
        );
      }
    } finally {
      // if (mounted) {
      setState(() {
        _cancellingInvites.remove(invitationId);
      });
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: _cancelInvitation completed');
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          automaticallyImplyLeading: true,
          foregroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
          title: const CustomTextWidget(
            text: 'Zusammenarbeit',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            onTap: (value) async {
              // Only mark notifications as read when user actually views the received tab
              // This ensures red dot disappears only when user intentionally views notifications
              if (value == 1) {
                await _markAllCollabNotificationsAsRead();
              }
            },
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 5,
            labelColor: Colors.white,
            controller: _tabController,
            unselectedLabelColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: 'Gesendet'),
              Tab(
                  child: StreamBuilder<bool>(
                      stream: _hasNewCollabNotificationStream,
                      initialData: false,
                      builder: (context, snapshot) {
                        final hasNewCollabNotification = snapshot.data ?? false;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            CustomTextWidget(
                              text: 'Empfangen',
                              color: Colors.white,
                            ),
                            if (hasNewCollabNotification)
                              Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                              ),
                          ],
                        );
                      })),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Ausstehende Einladungen',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        (() {
                          if (pendingInvitations == null) {
                            pendingInvitations = _sentInvitations
                                .where((invite) =>
                                    invite['status'] == 'pending' ||
                                    invite['status'] == 'accepted')
                                .toList();
                          }
                          if (pendingInvitations?.isEmpty ?? true) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CustomTextWidget(
                                  text: 'Keine ausstehenden Einladungen',
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingInvitations!.length,
                            itemBuilder: (context, index) {
                              final invite = pendingInvitations![index];
                              print('inviteeIdEEEE: ${invite}');
                              final inviteeId = invite['inviteeId'] as String?;
                              String inviteeName = 'Unbekannt';
                              if (inviteeId != null) {
                                final invitee = _userCache[inviteeId];
                                if (invitee != null &&
                                    invitee['name'] != null) {
                                  inviteeName = invitee['name']!;
                                }
                              }
                              final isAccepting =
                                  _acceptingInvites.contains(invite['id']);
                              final isCancelling =
                                  _cancellingInvites.contains(invite['id']);
                              final _emailInvitee =
                                  invite['inviteeEmail'] ?? '';
                              // final todoCount = invite['todoCount'] ?? 1;
                              final todoNames =
                                  (invite['todoNames'] as List?)?.join(', ') ??
                                      '';
                              final currentUserName = FirebaseAuth
                                      .instance.currentUser?.displayName ??
                                  invite['inviterName'] ??
                                  'Ich';
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
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
                                                // if (todoNames.isNotEmpty)
                                                //   CustomTextWidget(
                                                //     text: 'Listen: $todoNames',
                                                //     color: Colors.black,
                                                //   ),
                                                // const SizedBox(height: 4),
                                                CustomTextWidget(
                                                  text:
                                                      'Eingeladen: $_emailInvitee',
                                                  color: Colors.black,
                                                ),
                                                if (invite['createdAt'] != null)
                                                  CustomTextWidget(
                                                    text: 'Gesendet am: '
                                                        '${(invite['createdAt'] is Timestamp ? (invite['createdAt'] as Timestamp).toDate() : invite['createdAt']).toString().split(" ")[0]}',
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _cancelInvitation(
                                                  invite['id'], invite);
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  left: 10),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.red.withOpacity(0.6),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: isCancelling
                                                  ? Center(
                                                      child: SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  : Icon(Icons.remove,
                                                      size: 16,
                                                      color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        })(),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Erhaltene Einladungen',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        (() {
                          final pendingInvitations = _receivedInvitations
                              .where((invite) => invite['status'] == 'pending')
                              .toList();
                          if (pendingInvitations.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CustomTextWidget(
                                  text: 'Keine erhaltenen Einladungen',
                                  color: Colors.black,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingInvitations.length,
                            itemBuilder: (context, index) {
                              final invite = pendingInvitations[index];
                              final isNonRegistered =
                                  invite['isNonRegistered'] == true;
                              final inviter = isNonRegistered
                                  ? null
                                  : _userCache[invite['inviterId']];
                              final inviterName = isNonRegistered
                                  ? (invite['inviterEmail'] ?? 'Unbekannt')
                                  : (inviter?['name'] ?? 'Unbekannt');
                              final isAccepting =
                                  _acceptingInvites.contains(invite['id']);
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomTextWidget(
                                        text: 'Eingeladene von: '
                                            '${invite['inviterName'] ?? invite['inviterEmail'] ?? 'Unbekannt'}',
                                        color: Colors.black,
                                      ),
                                      if (invite['createdAt'] != null)
                                        CustomTextWidget(
                                          text: 'Gesendet am: '
                                              '${invite['createdAt'] is Timestamp ? (invite['createdAt'] as Timestamp).toDate().toString().split(" ")[0] : invite['createdAt'].toString().split(" ")[0]}',
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      const SpacerWidget(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        spacing: 10,
                                        children: [
                                          Expanded(
                                            child: CustomButtonWidget(
                                              text: 'Ablehnen',
                                              color: Colors.white,
                                              textColor: Colors.red,
                                              onPressed: () =>
                                                  _respondToInvitation(
                                                      invite['id'], false),
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomButtonWidget(
                                              text: 'Akzeptieren',
                                              color: Color.fromARGB(
                                                  255, 107, 69, 106),
                                              textColor: Colors.white,
                                              onPressed: isAccepting
                                                  ? null
                                                  : () => _respondToInvitation(
                                                      invite['id'], true),
                                              isLoading: isAccepting,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        })(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

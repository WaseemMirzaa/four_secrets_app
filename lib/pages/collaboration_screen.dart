import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';
import 'package:four_secrets_wedding_app/services/todo_service.dart';
import 'package:four_secrets_wedding_app/services/collaboration_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import '../widgets/custom_button_widget.dart';
import '../services/push_notification_service.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({Key? key}) : super(key: key);

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen>
    with SingleTickerProviderStateMixin {
  final TodoService _todoService = TodoService();
  final CollaborationService _collaborationService = CollaborationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();
  List<ToDoModel> _ownedTodos = [];
  List<ToDoModel> _collaboratedTodos = [];
  List<Map<String, dynamic>> _sentInvitations = [];
  List<Map<String, dynamic>> _receivedInvitations = [];
  Map<String, Map<String, String>> _userCache = {};
  bool _isLoading = true;

  late TabController _tabController;
  final key = GlobalKey<MenueState>();
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final Set<String> _acceptingInvites =
      {}; // Track loading state for accepting invites
  final Set<String> _cancellingInvites =
      {}; // Track loading state for cancelling invites

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final myEmail = _auth.currentUser?.email;
      if (myEmail == null) return;
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
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
      SnackBarHelper.showErrorSnackBar(
          context, "Error loading collaboration data: $e");
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

  Future<void> _respondToInvitation(String invitationId, bool accept) async {
    // Find the invite in the received invitations
    final invite = _receivedInvitations.firstWhere(
      (element) => element['id'] == invitationId,
      orElse: () => {},
    );
    final isNonRegistered = invite['isNonRegistered'] == true;
    if (accept) {
      setState(() {
        _acceptingInvites.add(invitationId);
      });
    }
    try {
      if (isNonRegistered) {
        // Accept the non-registered invite
        await _collaborationService.respondToInvitationForAllTodos(
            invitationId, accept);
      } else if (invite.containsKey('todoIds')) {
        // Multi-todo invite
        await _collaborationService.respondToInvitationForAllTodos(
            invitationId, accept);
      } else if (invite.containsKey('todoId')) {
        // Single-todo invite
        await _collaborationService.respondToInvitation(invitationId, accept);
        // await _pushNotificationService.sendInvitationAcceptedNotification(inviterId: inviterId, inviteeName: inviteeName, todoName: todoName)
      } else {
        throw Exception('Invalid invitation format');
      }
      await _loadData();
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          accept ? 'Einladung akzeptiert' : 'Einladung abgelehnt',
        );
        if (accept) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Fehler beim Antworten auf die Einladung: $e',
        );
      }
    } finally {
      if (accept) {
        setState(() {
          _acceptingInvites.remove(invitationId);
        });
      }
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    setState(() {
      _cancellingInvites.add(invitationId);
    });
    try {
      await _firestore.collection('invitations').doc(invitationId).delete();
      await _loadData();
      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Einladung storniert',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Fehler beim Stornieren der Einladung: $e',
        );
      }
    } finally {
      setState(() {
        _cancellingInvites.remove(invitationId);
      });
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
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 5,
            labelColor: Colors.white,
            controller: _tabController,
            unselectedLabelColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: 'Gesendet'),
              Tab(text: 'Empfangen'),
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
                          final pendingInvitations = _sentInvitations
                              .where((invite) => invite['status'] == 'pending')
                              .toList();
                          if (pendingInvitations.isEmpty) {
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
                            itemCount: pendingInvitations.length,
                            itemBuilder: (context, index) {
                              final invite = pendingInvitations[index];
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
                              final todoCount = invite['todoCount'] ?? 1;
                              final todoNames =
                                  (invite['todoNames'] as List?)?.join(', ') ??
                                      '';
                              final currentUserName = FirebaseAuth
                                      .instance.currentUser?.displayName ??
                                  invite['inviterName'] ??
                                  'Ich';
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
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
                                                CustomTextWidget(
                                                  text:
                                                      'Geteilte Listen: $todoCount',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                                if (todoNames.isNotEmpty)
                                                  CustomTextWidget(
                                                    text: 'Listen: $todoNames',
                                                    color: Colors.black,
                                                  ),
                                                const SizedBox(height: 4),
                                                CustomTextWidget(
                                                  text:
                                                      'Eingeladen: $currentUserName',
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
                                            onTap: () =>
                                                _cancelInvitation(invite['id']),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  left: 10),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.red.withOpacity(0.3),
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
                                      const SizedBox(height: 8),
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
                                  color: Colors.grey.shade300,
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
                                        text: (invite['todoCategories'] != null &&
                                                (invite['todoCategories'] as List)
                                                    .expand((cat) =>
                                                        (cat['categories'] as List? ??
                                                            []))
                                                    .map((category) =>
                                                        category['categoryName'] ??
                                                        '')
                                                    .where((name) => name
                                                        .toString()
                                                        .trim()
                                                        .isNotEmpty)
                                                    .toList()
                                                    .isNotEmpty
                                            ? (invite['todoCategories'] as List)
                                                .expand((cat) =>
                                                    (cat['categories'] as List? ??
                                                        []))
                                                .map((category) =>
                                                    category['categoryName'] ?? '')
                                                .where((name) => name.toString().trim().isNotEmpty)
                                                .join(', ')
                                            : 'Ohne Kategorie'),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      const SizedBox(height: 8),
                                      CustomTextWidget(
                                        text: 'Eingeladene von: '
                                            '${invite['inviteeName'] ?? invite['inviteeEmail'] ?? 'Unbekannt'}',
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';
import 'package:four_secrets_wedding_app/services/push_notification_service.dart';
import 'package:four_secrets_wedding_app/widgets/comment_input_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';

import '../utils/snackbar_helper.dart';
import '../widgets/spacer_widget.dart';

class CollaborationTodoTile extends StatefulWidget {
  final String collabId;
  final Color color;
  final Color labelColor;
  final Color labelTextColor;
  final Color checkboxColor;
  final Color avatarColor;
  final String collectionPath;
  final bool showTag;

  CollaborationTodoTile({
    Key? key,
    required this.collabId,
    required this.color,
    required this.labelColor,
    required this.labelTextColor,
    required this.checkboxColor,
    required this.avatarColor,
    required this.collectionPath,
    this.showTag = true,
  }) : super(key: key);

  final TextEditingController editingController = TextEditingController();

  // Add a key to access the state
  final GlobalKey<_CollaborationTodoTileState> tileKey = GlobalKey();

  @override
  State<CollaborationTodoTile> createState() => _CollaborationTodoTileState();
}

class _CollaborationTodoTileState extends State<CollaborationTodoTile> {
  int? editingCommentIndex;
  Map<String, dynamic>? editingComment;
  bool isEditingComment = false;
  bool _isExpanded = false;

  String? _cachedOwnerName;
  DateTime? _selectedReminderDate;
  TimeOfDay? _selectedReminderTime;
  String? _selectedReminderDateText;
  String? _selectedReminderTimeText;
  bool _reminderEnabled = false;
  String? _reminderIso;

  @override
  void initState() {
    super.initState();
    // Reminder state will be initialized in _buildTileContent from Firestore data
  }

  Future<String> _getOwnerName(String ownerEmail, String ownerName) async {
    if (ownerName.isNotEmpty) return ownerName;
    if (_cachedOwnerName != null) return _cachedOwnerName!;
    // Fetch UID from users collection by email
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: ownerEmail)
        .limit(1)
        .get();
    String? ownerUid;
    if (userQuery.docs.isNotEmpty) {
      ownerUid = userQuery.docs.first.id;
    } else {
      // fallback: use email as UID (legacy)
      ownerUid = ownerEmail;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .get();
    final name = doc.data()?['name'] ?? ownerName;
    _cachedOwnerName = name;
    return name;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return 'vor ${difference.inDays} Tagen';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} Stunden';
    } else if (difference.inMinutes > 0) {
      return 'vor ${difference.inMinutes} Minuten';
    } else {
      return 'Gerade eben';
    }
  }

  Future<void> _markNotificationsAsReadForTodo(String todoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('token', isEqualTo: fcmToken)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['data']?['todoId'] == todoId) {
        await doc.reference.update({'read': true});
      }
    }
  }

  Future<void> _sendCommentNotifications(
      String commenterName, String comment) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get the todo document to access collaborators and owner info
      final todoDoc = await FirebaseFirestore.instance
          .collection(widget.collectionPath)
          .doc(widget.collabId)
          .get();

      if (!todoDoc.exists) return;

      final todoData = todoDoc.data()!;
      final collaborators = List<String>.from(todoData['collaborators'] ?? []);
      final ownerEmail = todoData['ownerEmail'] as String?;
      final categoryName = todoData['categories']?.isNotEmpty == true
          ? todoData['categories'][0]['categoryName'] ?? 'Todo'
          : 'Todo';

      // Collect all users to notify (collaborators + owner, excluding commenter)
      final usersToNotify = <String>{};

      // Add collaborators
      for (final collaboratorEmail in collaborators) {
        if (collaboratorEmail != currentUser.email) {
          usersToNotify.add(collaboratorEmail);
        }
      }

      // Add owner if different from commenter
      if (ownerEmail != null && ownerEmail != currentUser.email) {
        usersToNotify.add(ownerEmail);
      }

      print('🔔 Sending comment notifications to: $usersToNotify');

      // Send notifications to each user
      for (final userEmail in usersToNotify) {
        await _sendNotificationToUser(
          userEmail: userEmail,
          commenterName: commenterName,
          comment: comment,
          categoryName: categoryName,
        );
      }
    } catch (e) {
      print('🔴 Error sending comment notifications: $e');
    }
  }

  Future<void> _sendNotificationToUser({
    required String userEmail,
    required String commenterName,
    required String comment,
    required String categoryName,
  }) async {
    try {
      // Find user by email to get FCM token
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('🔴 User not found for email: $userEmail');
        return;
      }

      final userDoc = userQuery.docs.first;
      final fcmToken = userDoc.data()['fcmToken'] as String?;

      if (fcmToken == null) {
        print('🔴 No FCM token found for user: $userEmail');
        return;
      }

      // Truncate comment if too long for notification
      final truncatedComment =
          comment.length > 50 ? '${comment.substring(0, 50)}...' : comment;

      // Send notification via external API
      final pushService = PushNotificationService();
      await pushService.sendNotificationByEmail(
        email: userEmail,
        title: 'Neuer Kommentar in $categoryName',
        body: '$commenterName: $truncatedComment',
        data: {
          'type': 'comment',
          'todoId': widget.collabId,
          'categoryName': categoryName,
          'commenterName': commenterName,
        },
      );

      print('🔔 Notification sent to $userEmail for comment in $categoryName');
    } catch (e) {
      print('🔴 Error sending notification to $userEmail: $e');
    }
  }

  // Send notification to a specific user for checkbox changes
  Future<void> _sendCheckboxNotificationToUser({
    required String userEmail,
    required String changerName,
    required String itemName,
    required bool isChecked,
    required String categoryName,
  }) async {
    try {
      // Send notification via external API
      final action = isChecked ? 'abgehakt' : 'nicht abgehakt';
      final pushService = PushNotificationService();
      await pushService.sendNotificationByEmail(
        email: userEmail,
        title: 'Aufgabe $action in $categoryName',
        body: '$changerName hat "$itemName" $action',
        data: {
          'type': 'checkbox_change',
          'todoId': widget.collabId,
          'categoryName': categoryName,
          'changerName': changerName,
          'itemName': itemName,
          'isChecked': isChecked,
        },
      );

      print('🔔 Checkbox notification sent to $userEmail for item: $itemName');
    } catch (e) {
      print('🔴 Error sending checkbox notification to $userEmail: $e');
    }
  }

  // Send checkbox notifications to all collaborators and owner except the changer
  Future<void> _sendCheckboxNotifications(
      String changerName, String itemName, bool isChecked) async {
    try {
      // Get category name from document data
      final todoDoc = await FirebaseFirestore.instance
          .collection(widget.collectionPath)
          .doc(widget.collabId)
          .get();

      if (!todoDoc.exists) {
        print('🔴 Todo document not found');
        return;
      }

      final data = todoDoc.data()!;
      final categories =
          List<Map<String, dynamic>>.from(data['categories'] ?? []);
      final categoryName = categories.isNotEmpty
          ? (categories.first['categoryName'] ?? 'Todo')
          : 'Todo';

      // Get current user email
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

      // Use the already fetched data
      final ownerEmail = data['ownerEmail'] as String?;
      final collaborators = List<String>.from(data['collaborators'] ?? []);

      // Create list of users to notify (exclude the changer)
      final usersToNotify = <String>{};

      // Add owner if different from changer
      if (ownerEmail != null && ownerEmail != currentUserEmail) {
        usersToNotify.add(ownerEmail);
      }

      // Add collaborators (exclude changer)
      for (final collaborator in collaborators) {
        if (collaborator != currentUserEmail) {
          usersToNotify.add(collaborator);
        }
      }

      // Send notifications to all relevant users
      for (final userEmail in usersToNotify) {
        await _sendCheckboxNotificationToUser(
          userEmail: userEmail,
          changerName: changerName,
          itemName: itemName,
          isChecked: isChecked,
          categoryName: categoryName,
        );
      }

      print('🔔 Sent checkbox notifications to ${usersToNotify.length} users');
    } catch (e) {
      print('🔴 Error sending checkbox notifications: $e');
    }
  }

  // Get current user's name
  Future<String> _getCurrentUserName() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'Unbekannt';

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? 'Unbekannt';
      }
      return 'Unbekannt';
    } catch (e) {
      print('🔴 Error getting current user name: $e');
      return 'Unbekannt';
    }
  }

  bool calculateHasUnread(Map<String, dynamic> data, String currentUserEmail) {
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    Timestamp? lastRead;
    if (data['commentReadTimestamps'] != null) {
      final map = data['commentReadTimestamps'] as Map<String, dynamic>;
      if (map[encodeEmailForFirestore(currentUserEmail)] != null) {
        var value = map[encodeEmailForFirestore(currentUserEmail)];
        if (value is Timestamp) {
          lastRead = value;
        } else if (value is int) {
          lastRead = Timestamp.fromMillisecondsSinceEpoch(value);
        } else {}
      }
    }
    // Find latest comment or checkbox activity by someone else
    Timestamp? latestCommentTs;
    if (comments.isNotEmpty) {
      final otherComments =
          comments.where((c) => c['userId'] != currentUserEmail).toList()
            ..sort((a, b) {
              final ta = a['timestamp'];
              final tb = b['timestamp'];
              if (ta is Timestamp && tb is Timestamp) {
                return tb.compareTo(ta);
              }
              return 0;
            });
      if (otherComments.isNotEmpty) {
        final ts = otherComments.first['timestamp'];
        if (ts is Timestamp) {
          latestCommentTs = ts;
        } else if (ts is DateTime) {
          latestCommentTs = Timestamp.fromDate(ts);
        }
      }
    }
    // Checkbox activity by someone else
    final lastActivityUserId = data['lastActivityUserId'];
    Timestamp? lastActivityTs =
        (lastActivityUserId != null && lastActivityUserId != currentUserEmail)
            ? (data['lastActivityTimestamp'] is Timestamp
                ? data['lastActivityTimestamp'] as Timestamp?
                : (data['lastActivityTimestamp'] is DateTime
                    ? Timestamp.fromDate(data['lastActivityTimestamp'])
                    : null))
            : null;
    // Use the latest of these two
    Timestamp? latestTs;
    if (latestCommentTs != null && lastActivityTs != null) {
      latestTs = latestCommentTs.compareTo(lastActivityTs) > 0
          ? latestCommentTs
          : lastActivityTs;
    } else {
      latestTs = latestCommentTs ?? lastActivityTs;
    }
    print('[calculateHasUnread] latestTs: ' +
        (latestTs?.toString() ?? 'null') +
        ' type: ' +
        (latestTs?.runtimeType.toString() ?? 'null') +
        ', lastRead: ' +
        (lastRead?.toString() ?? 'null') +
        ' type: ' +
        (lastRead?.runtimeType.toString() ?? 'null'));
    if (latestTs != null && lastRead != null) {
      return latestTs.compareTo(lastRead) > 0;
    } else if (latestTs != null && lastRead == null) {
      return true;
    }
    return false;
  }

  Timestamp? calculateLatestTs(
      Map<String, dynamic> data, String currentUserEmail) {
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    Timestamp? latestNonCurrentUserCommentTs;
    if (comments.isNotEmpty) {
      final nonCurrentUserComments =
          comments.where((c) => c['userId'] != currentUserEmail).toList()
            ..sort((a, b) {
              final ta = a['timestamp'];
              final tb = b['timestamp'];
              if (ta is Timestamp && tb is Timestamp) {
                return tb.compareTo(ta);
              }
              return 0;
            });
      if (nonCurrentUserComments.isNotEmpty) {
        latestNonCurrentUserCommentTs =
            nonCurrentUserComments.first['timestamp'] as Timestamp?;
      }
    }
    final lastActivityUserId = data['lastActivityUserId'];
    Timestamp? lastActivityTs =
        (lastActivityUserId != null && lastActivityUserId != currentUserEmail)
            ? data['lastActivityTimestamp'] as Timestamp?
            : null;
    Timestamp? latestTs;
    if (latestNonCurrentUserCommentTs != null && lastActivityTs != null) {
      latestTs = latestNonCurrentUserCommentTs.compareTo(lastActivityTs) > 0
          ? latestNonCurrentUserCommentTs
          : lastActivityTs;
    } else {
      latestTs = latestNonCurrentUserCommentTs ?? lastActivityTs;
    }
    return latestTs;
  }

  Future<void> _selectReminderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedReminderDate = picked;
        _selectedReminderDateText =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _selectedReminderTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedReminderTime = picked;
        _selectedReminderTimeText =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} Uhr";
      });
    }
  }

  Future<void> _saveReminder(String collectionPath, String collabId,
      String? reminderIso, String todoName) async {
    await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(collabId)
        .update({'reminder': reminderIso});
    if (reminderIso != null) {
      await NotificationService.scheduleAlarmNotification(
        id: collabId.hashCode,
        dateTime: DateTime.parse(reminderIso),
        title: todoName,
        body: 'Erinnerung für Ihre Aufgabe',
        payload: collabId,
      );
    }
  }

  Widget _buildCommentTile(
      String? profilePicUrl,
      String displayName,
      Map<String, dynamic> comment,
      Color avatarColor,
      String currentUserEmail,
      int index,
      TextEditingController editingController,
      List<Map<String, dynamic>> comments,
      {Widget? trailing}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: avatarColor,
                child: (profilePicUrl != null && profilePicUrl.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          profilePicUrl,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return CustomTextWidget(
                              text: (displayName.isNotEmpty
                                  ? displayName[0]
                                  : 'U'),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 16,
                            );
                          },
                        ),
                      )
                    : CustomTextWidget(
                        text: (displayName.isNotEmpty ? displayName[0] : 'U'),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        if (trailing != null) ...[SizedBox(width: 6), trailing],
                      ],
                    ),
                    if (comment['timestamp'] != null)
                      Text(
                        _formatTimestamp(comment['timestamp']),
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (comment['userId'] == currentUserEmail)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      setState(() {
                        editingCommentIndex = index;
                        editingComment = comment;
                        editingController.text = comment['comment'] ?? '';
                        isEditingComment = true;
                      });
                    } else if (value == 'delete') {
                      // Confirm before deleting
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => CustomDialog(
                          title: 'Kommentar löschen',
                          message:
                              'Möchten Sie diesen Kommentar wirklich löschen?',
                          confirmText: 'Löschen',
                          cancelText: 'Abbrechen',
                          onConfirm: () async {
                            Navigator.pop(context, true);
                          },
                          onCancel: () {
                            Navigator.pop(context, false);
                          },
                        ),
                      );
                      if (confirm == true) {
                        try {
                          List<Map<String, dynamic>> updatedComments =
                              List<Map<String, dynamic>>.from(comments);
                          updatedComments.removeWhere((c) =>
                              c['userId'] == comment['userId'] &&
                              c['timestamp'] == comment['timestamp'] &&
                              c['comment'] == comment['comment']);
                          await FirebaseFirestore.instance
                              .collection(widget.collectionPath)
                              .doc(widget.collabId)
                              .update({'comments': updatedComments});
                          if (context.mounted) {
                            SnackBarHelper.showSuccessSnackBar(
                                context, 'Kommentar gelöscht');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            SnackBarHelper.showErrorSnackBar(context,
                                'Fehler beim Löschen des Kommentars: $e');
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.penToSquare,
                              color: Color(0xFF6B456A), size: 18),
                          const SizedBox(width: 8),
                          CustomTextWidget(
                              color: Color(0xFF6B456A), text: 'Bearbeiten'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.trashCan,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          CustomTextWidget(color: Colors.red, text: 'Löschen'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            child: CustomTextWidget(
              text: comment['comment'] ?? '',
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileContent(
      BuildContext context, Map<String, dynamic> data, String currentUserEmail,
      {required bool isRevoked}) {
    final categories =
        List<Map<String, dynamic>>.from(data['categories'] ?? []);
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    final ownerName = data['ownerName'] ?? '';
    final ownerId = data['ownerEmail'] ?? '';
    final todoName = data['todoName'] ?? '';
    final revokedFor = List<String>.from(data['revokedFor'] ?? []);
    final allCollaborators = List<String>.from(data['collaborators'] ?? []);
    final collaborators =
        allCollaborators.where((email) => email != currentUserEmail).toList();
    final categoryName = (categories.isNotEmpty &&
            categories[0]['categoryName'] != null &&
            categories[0]['categoryName'].toString().isNotEmpty)
        ? categories[0]['categoryName']
        : todoName;
    // NEW LOGIC: Check if current user is the actual owner
    final isOwned = (ownerId == currentUserEmail);
    final isRevokedFlag = !isOwned && revokedFor.contains(currentUserEmail);
    // Debug prints for collaboration state
    debugPrint('[CollabTile] currentUserId: $currentUserEmail');
    debugPrint('[CollabTile] ownerId: $ownerId');
    debugPrint('[CollabTile] isOwned: $isOwned');
    debugPrint('[CollabTile] isRevoked parameter: $isRevoked');
    // --- Unread logic for comments and checkbox changes ---
    final bool _hasUnread = calculateHasUnread(data, currentUserEmail);

    // Print the latest activity and lastRead used in calculation
    {
      final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
      Timestamp? lastRead;
      if (data['commentReadTimestamps'] != null) {
        final map = data['commentReadTimestamps'] as Map<String, dynamic>;
        if (map[encodeEmailForFirestore(currentUserEmail)] != null) {
          lastRead = map[encodeEmailForFirestore(currentUserEmail)] is Timestamp
              ? map[encodeEmailForFirestore(currentUserEmail)]
              : (map[encodeEmailForFirestore(currentUserEmail)] is int
                  ? Timestamp.fromMillisecondsSinceEpoch(
                      map[encodeEmailForFirestore(currentUserEmail)])
                  : null);
        }
      }
      Timestamp? latestCommentTs;
      if (comments.isNotEmpty) {
        final otherComments =
            comments.where((c) => c['userId'] != currentUserEmail).toList()
              ..sort((a, b) {
                final ta = a['timestamp'];
                final tb = b['timestamp'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                return 0;
              });
        if (otherComments.isNotEmpty) {
          latestCommentTs = otherComments.first['timestamp'] as Timestamp?;
        }
      }
      final lastActivityUserId = data['lastActivityUserId'];
      Timestamp? lastActivityTs =
          (lastActivityUserId != null && lastActivityUserId != currentUserEmail)
              ? data['lastActivityTimestamp'] as Timestamp?
              : null;
      Timestamp? latestTs;
      if (latestCommentTs != null && lastActivityTs != null) {
        latestTs = latestCommentTs.compareTo(lastActivityTs) > 0
            ? latestCommentTs
            : lastActivityTs;
      } else {
        latestTs = latestCommentTs ?? lastActivityTs;
      }
      print('[buildTileContent] latestTs: ' +
          (latestTs?.toString() ?? 'null') +
          ', lastRead: ' +
          (lastRead?.toString() ?? 'null'));
    }
    final editingController = widget.editingController;
    final labelColor = widget.labelColor;
    final labelTextColor = widget.labelTextColor;
    final avatarColor = widget.avatarColor;
    final checkboxColor = widget.checkboxColor;
    final showTag = widget.showTag;

    // Debug tag visibility
    debugPrint(
        '[CollabTile] showTag: $showTag, Will show tag: ${showTag && !isOwned}');

    final reminderStr = data['reminder'] as String?;
    if (reminderStr != null && reminderStr.isNotEmpty) {
      final reminderDateTime = DateTime.tryParse(reminderStr);
      if (reminderDateTime != null) {
        _reminderEnabled = true;
        _selectedReminderDate = reminderDateTime;
        _selectedReminderTime = TimeOfDay.fromDateTime(reminderDateTime);
        _selectedReminderDateText =
            "${reminderDateTime.day.toString().padLeft(2, '0')}/${reminderDateTime.month.toString().padLeft(2, '0')}/${reminderDateTime.year}";
        _selectedReminderTimeText =
            "${reminderDateTime.hour.toString().padLeft(2, '0')}:${reminderDateTime.minute.toString().padLeft(2, '0')} Uhr";
        _reminderIso = reminderDateTime.toIso8601String();
      }
    }

    // --- REVOKED VIEW: Show full tile, but all interactive elements disabled ---
    if (isRevoked) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade300,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            ExpansionTile(
              shape: OutlineInputBorder(borderSide: BorderSide.none),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: CustomTextWidget(
                                text: categoryName,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_hasUnread)
                              Container(
                                margin: EdgeInsets.only(left: 6),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(child: SizedBox(width: 10)),
                      // Hide edit/delete buttons for revoked users
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Always show the tag for revoked users
                  FutureBuilder<String>(
                    future: _getOwnerName(ownerId, ownerName),
                    builder: (context, snapshot) {
                      final displayName =
                          snapshot.hasData ? snapshot.data! : ownerName;
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: labelColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomTextWidget(
                          text: 'Geteilt von $displayName',
                          color: labelTextColor,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
              children: [
                if (categories.isNotEmpty)
                  ...List.generate(categories.length, (catIdx) {
                    var cat = categories[catIdx];
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
                                  onChanged:
                                      null, // Always disabled for revoked
                                  activeColor: checkboxColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    itemName,
                                    style: TextStyle(
                                      decoration: isChecked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kommentare:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection(widget.collectionPath)
                            .doc(widget.collabId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return SizedBox();
                          }
                          final data = snapshot.data!.data();
                          final comments = List<Map<String, dynamic>>.from(
                              data?['comments'] ?? []);
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final String? commentUserId = comment['userId'];
                              return FutureBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                future: commentUserId != null
                                    ? FirebaseFirestore.instance
                                        .collection('users')
                                        .where('email',
                                            isEqualTo: commentUserId)
                                        .limit(1)
                                        .get()
                                    : null,
                                builder: (context, userSnapshot) {
                                  String? profilePicUrl;
                                  String displayName = '';
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    // Show a small loading indicator while loading
                                    return _buildCommentTile(
                                      null,
                                      '', // No displayName yet
                                      comment,
                                      avatarColor,
                                      currentUserEmail,
                                      index,
                                      widget.editingController,
                                      comments,
                                      trailing: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    );
                                  } else if (userSnapshot.connectionState ==
                                          ConnectionState.done &&
                                      userSnapshot.hasData &&
                                      userSnapshot.data!.docs.isNotEmpty) {
                                    final userData =
                                        userSnapshot.data!.docs.first.data();
                                    profilePicUrl =
                                        userData['profilePictureUrl']
                                            as String?;
                                    displayName = userData != null
                                        ? (userData['name'] ??
                                            comment['userName'] ??
                                            'Unbekannt')
                                        : (comment['userName'] ?? 'Unbekannt');
                                    return _buildCommentTile(
                                      profilePicUrl,
                                      displayName,
                                      comment,
                                      avatarColor,
                                      currentUserEmail,
                                      index,
                                      widget.editingController,
                                      comments,
                                    );
                                  } else {
                                    profilePicUrl = null;
                                    displayName =
                                        comment['userName'] ?? 'Unbekannt';
                                    return _buildCommentTile(
                                      profilePicUrl,
                                      displayName,
                                      comment,
                                      avatarColor,
                                      currentUserEmail,
                                      index,
                                      widget.editingController,
                                      comments,
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
              onExpansionChanged: (expanded) async {
                setState(() {
                  _isExpanded = expanded;
                });
                if (expanded && currentUserEmail.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection(widget.collectionPath)
                      .doc(widget.collabId)
                      .update({
                    'commentReadTimestamps.${encodeEmailForFirestore(currentUserEmail)}':
                        Timestamp.now(),
                  });
                  await _markNotificationsAsReadForTodo(widget.collabId);
                  await Future.delayed(Duration(milliseconds: 200));
                  if (mounted) setState(() {});
                }
              },
            ),
            // Show the comment input field, but disabled
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: CommentInputField(
                collabId: widget.collabId,
                controller: widget.editingController,
                label: 'Kommentar hinzufügen...',
                sendIcon: Icons.send,
                loadingColor: Color.fromARGB(255, 107, 69, 106),
                editMode: false,
                onEdit: null,
                onCancel: null,
                onSend: null,
                enabled: false, // Always disabled for revoked
              ),
            ),
            SpacerWidget(height: 3),
          ],
        ),
      );
    }
    // --- END REVOKED VIEW ---

    // ... existing code for non-revoked users ...
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        // color: widget.color,
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ExpansionTile(
            // pad
            shape: OutlineInputBorder(borderSide: BorderSide.none),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextWidget(
                        text: categoryName,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_hasUnread)
                      Container(
                        margin: EdgeInsets.only(left: 6),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isOwned) ...[
                      IconButton(
                        icon: Icon(FontAwesomeIcons.penToSquare,
                            color: Color(0xFF6B456A), size: 20),
                        tooltip: 'Bearbeiten',
                        onPressed: () async {
                          // Ensure we have the owner's UID (ownerId) and email (ownerEmail)
                          String? ownerUid = data['ownerId'];
                          String? ownerEmail = data['ownerEmail'];
                          if ((ownerUid == null || ownerUid.isEmpty) &&
                              ownerEmail != null &&
                              ownerEmail.isNotEmpty) {
                            // Fetch UID from users collection by email
                            final userQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('email', isEqualTo: ownerEmail)
                                .limit(1)
                                .get();
                            if (userQuery.docs.isNotEmpty) {
                              ownerUid = userQuery.docs.first.id;
                            }
                          }
                          if (ownerUid == null || ownerUid.isEmpty) {
                            SnackBarHelper.showErrorSnackBar(
                                context, 'Owner UID not found!');
                            return;
                          }
                          Navigator.of(context).pushNamed(
                            '/addToDoPage',
                            arguments: {
                              'toDoModel': ToDoModel(
                                id: widget.collabId,
                                toDoName: todoName,
                                userId: ownerUid,
                                ownerEmail: ownerEmail,
                                categoryId: data['categoryId'],
                                collaborators: List<String>.from(
                                    data['collaborators'] ?? []),
                                comments: List<Map<String, dynamic>>.from(
                                    data['comments'] ?? []),
                                toDoItems: data['toDoItems'] != null
                                    ? List<Map<String, dynamic>>.from(
                                        data['toDoItems'])
                                    : null,
                                reminder: data['reminder'],
                                categories: categories,
                                isShared: data['isShared'] ?? false,
                              ),
                              'id': widget.collabId,
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(FontAwesomeIcons.trashCan,
                            color: Colors.red, size: 20),
                        tooltip: 'Löschen',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => CustomDialog(
                              title: 'To-Do löschen',
                              message:
                                  'Möchten Sie dieses To-Do wirklich löschen?',
                              confirmText: 'Löschen',
                              cancelText: 'Abbrechen',
                              onConfirm: () async {
                                Navigator.pop(context, true);
                              },
                              onCancel: () {
                                Navigator.pop(context, false);
                              },
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection(widget.collectionPath)
                                  .doc(widget.collabId)
                                  .delete();
                              if (context.mounted) {
                                SnackBarHelper.showSuccessSnackBar(
                                    context, 'To-Do gelöscht');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                SnackBarHelper.showErrorSnackBar(
                                    context, 'Fehler beim Löschen: $e');
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // Always show "Shared by" tag for non-owned todos
                if (showTag && !isOwned)
                  FutureBuilder<String>(
                    future: _getOwnerName(ownerId, ownerName),
                    builder: (context, snapshot) {
                      final displayName =
                          snapshot.hasData ? snapshot.data! : ownerName;
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: labelColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomTextWidget(
                          text: 'Geteilt von $displayName',
                          color: labelTextColor,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
              ],
            ),
            children: [
              // Reminder Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextWidget(
                        text: _reminderIso != null && _reminderIso!.isNotEmpty
                            ? "Erinnerung: ${_selectedReminderDateText ?? ''} ${_selectedReminderTimeText ?? ''}"
                            : "Erinnerung hinzufügen",
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_reminderIso != null && _reminderIso!.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        tooltip: 'Erinnerung entfernen',
                        onPressed: () async {
                          setState(() {
                            _selectedReminderDate = null;
                            _selectedReminderTime = null;
                            _selectedReminderDateText = null;
                            _selectedReminderTimeText = null;
                            _reminderIso = null;
                          });
                          await _saveReminder(widget.collectionPath,
                              widget.collabId, null, categoryName);
                          await NotificationService.cancel(
                              widget.collabId.hashCode);
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.alarm_sharp, color: Color(0xFF6B456A)),
                      tooltip: _reminderIso != null && _reminderIso!.isNotEmpty
                          ? 'Erinnerung ändern'
                          : 'Erinnerung hinzufügen',
                      onPressed: () async {
                        // Pick date
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedReminderDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate == null) return;
                        // Pick time
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _selectedReminderTime ??
                              const TimeOfDay(hour: 12, minute: 0),
                        );
                        if (pickedTime == null) return;
                        setState(() {
                          _selectedReminderDate = pickedDate;
                          _selectedReminderTime = pickedTime;
                          _selectedReminderDateText =
                              "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                          _selectedReminderTimeText =
                              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')} Uhr";
                        });
                        final dt = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        _reminderIso = dt.toIso8601String();
                        await _saveReminder(widget.collectionPath,
                            widget.collabId, _reminderIso, categoryName);
                      },
                    ),
                  ],
                ),
              ),
              if (categories.isNotEmpty)
                ...List.generate(categories.length, (catIdx) {
                  var cat = categories[catIdx];
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
                                            categories);
                                    var itemsCopy = (categoriesCopy[catIdx]
                                            ['items'] as List)
                                        .map((e) => e is Map<String, dynamic>
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
                                    categoriesCopy[catIdx]['items'] = itemsCopy;
                                    final now = Timestamp.now();
                                    await FirebaseFirestore.instance
                                        .collection(widget.collectionPath)
                                        .doc(widget.collabId)
                                        .update({
                                      'categories': categoriesCopy,
                                      'lastActivityTimestamp': now,
                                    });

                                    // Send push notifications to all collaborators and owner
                                    final currentUser =
                                        FirebaseAuth.instance.currentUser;
                                    if (currentUser != null) {
                                      final userName =
                                          await _getCurrentUserName();
                                      final newIsChecked =
                                          !(item['isChecked'] ?? false);
                                      await _sendCheckboxNotifications(
                                          userName, itemName, newIsChecked);
                                    }

                                    if (mounted) setState(() {});
                                  } catch (e) {
                                    if (context.mounted) {
                                      SnackBarHelper.showErrorSnackBar(
                                          context, "Failed to update item: $e");
                                    }
                                  }
                                },
                                activeColor: checkboxColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  itemName,
                                  style: TextStyle(
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kommentare:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection(widget.collectionPath)
                          .doc(widget.collabId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return SizedBox();
                        }
                        final data = snapshot.data!.data();
                        final comments = List<Map<String, dynamic>>.from(
                            data?['comments'] ?? []);
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final String? commentUserId = comment['userId'];
                            return FutureBuilder<
                                QuerySnapshot<Map<String, dynamic>>>(
                              future: commentUserId != null
                                  ? FirebaseFirestore.instance
                                      .collection('users')
                                      .where('email', isEqualTo: commentUserId)
                                      .limit(1)
                                      .get()
                                  : null,
                              builder: (context, userSnapshot) {
                                String? profilePicUrl;
                                String displayName = '';
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // Show a small loading indicator while loading
                                  return _buildCommentTile(
                                    null,
                                    '', // No displayName yet
                                    comment,
                                    avatarColor,
                                    currentUserEmail,
                                    index,
                                    widget.editingController,
                                    comments,
                                    trailing: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  );
                                } else if (userSnapshot.connectionState ==
                                        ConnectionState.done &&
                                    userSnapshot.hasData &&
                                    userSnapshot.data!.docs.isNotEmpty) {
                                  final userData =
                                      userSnapshot.data!.docs.first.data();
                                  profilePicUrl =
                                      userData['profilePictureUrl'] as String?;
                                  displayName = userData != null
                                      ? (userData['name'] ??
                                          comment['userName'] ??
                                          'Unbekannt')
                                      : (comment['userName'] ?? 'Unbekannt');
                                  return _buildCommentTile(
                                    profilePicUrl,
                                    displayName,
                                    comment,
                                    avatarColor,
                                    currentUserEmail,
                                    index,
                                    widget.editingController,
                                    comments,
                                  );
                                } else {
                                  profilePicUrl = null;
                                  displayName =
                                      comment['userName'] ?? 'Unbekannt';
                                  return _buildCommentTile(
                                    profilePicUrl,
                                    displayName,
                                    comment,
                                    avatarColor,
                                    currentUserEmail,
                                    index,
                                    widget.editingController,
                                    comments,
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
            onExpansionChanged: (expanded) async {
              setState(() {
                _isExpanded = expanded;
              });
              if (expanded && currentUserEmail.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection(widget.collectionPath)
                    .doc(widget.collabId)
                    .update({
                  'commentReadTimestamps.${encodeEmailForFirestore(currentUserEmail)}':
                      Timestamp.now(),
                });
                await _markNotificationsAsReadForTodo(widget.collabId);
                await Future.delayed(Duration(milliseconds: 200));
                if (mounted) setState(() {});
              }
            },
          ),
          // Unified add/edit comment box always visible below the tile
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: CommentInputField(
              collabId: widget.collabId,
              controller: widget.editingController,
              label: isEditingComment
                  ? 'Kommentar bearbeiten...'
                  : 'Kommentar hinzufügen...',
              sendIcon: isEditingComment ? Icons.check : Icons.send,
              loadingColor: Color.fromARGB(255, 107, 69, 106),
              editMode: isEditingComment,
              onEdit: isEditingComment
                  ? (result) async {
                      if (result.isNotEmpty &&
                          editingComment != null &&
                          result != editingComment!['comment']) {
                        try {
                          List<Map<String, dynamic>> updatedComments =
                              List<Map<String, dynamic>>.from(comments);
                          int idx = updatedComments.indexWhere((c) =>
                              c['userId'] == editingComment!['userId'] &&
                              c['timestamp'] == editingComment!['timestamp'] &&
                              c['comment'] == editingComment!['comment']);
                          if (idx != -1) {
                            updatedComments[idx] = {
                              ...updatedComments[idx],
                              'comment': result,
                            };
                            await FirebaseFirestore.instance
                                .collection(widget.collectionPath)
                                .doc(widget.collabId)
                                .update({'comments': updatedComments});
                            if (context.mounted) {
                              SnackBarHelper.showSuccessSnackBar(
                                  context, 'Comment updated');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            SnackBarHelper.showErrorSnackBar(
                                context, 'Failed to update comment: $e');
                          }
                        }
                      }
                      setState(() {
                        editingCommentIndex = null;
                        editingComment = null;
                        widget.editingController.clear();
                        isEditingComment = false;
                      });
                    }
                  : null,
              onCancel: isEditingComment
                  ? () {
                      setState(() {
                        editingCommentIndex = null;
                        editingComment = null;
                        widget.editingController.clear();
                        isEditingComment = false;
                      });
                    }
                  : null,
              onSend: (value) async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                // Fetch user name from Firestore if displayName is not set
                String userName = user.displayName ?? '';
                if (userName.isEmpty) {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.email)
                      .get();
                  userName =
                      userDoc.data()?['name'] ?? user.email ?? 'Unbekannt';
                }
                final newComment = {
                  'userId': user.email,
                  'userName': userName,
                  'comment': value,
                  'timestamp': DateTime.now(),
                };
                List<Map<String, dynamic>> updatedComments =
                    List<Map<String, dynamic>>.from(comments);
                updatedComments.add(newComment);
                await FirebaseFirestore.instance
                    .collection(widget.collectionPath)
                    .doc(widget.collabId)
                    .update({'comments': updatedComments});

                // Send notifications to all collaborators and owner except the commenter
                await _sendCommentNotifications(userName, value);
              },
              enabled: true, // Always allow commenting
            ),
          ),
          SpacerWidget(height: 3),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    // Debug print for collabId and collectionPath
    debugPrint('[CollaborationTodoTile] collabId: '
        '\x1B[33m${widget.collabId}\x1B[0m, '
        'collectionPath: \x1B[32m${widget.collectionPath}\x1B[0m');
    // Use static snapshot for revoked users, real-time for others
    return Builder(
      builder: (context) {
        if (currentUserEmail == null) return SizedBox();
        // Use a FutureBuilder for revoked users (static), StreamBuilder for others (live)
        return _CollabTileContent(
          collabId: widget.collabId,
          collectionPath: widget.collectionPath,
          currentUserEmail: currentUserEmail,
          buildTileContent: _buildTileContent,
        );
      },
    );
  }
}

class _CollabTileContent extends StatefulWidget {
  final String collabId;
  final String collectionPath;
  final String currentUserEmail;
  final Widget Function(BuildContext, Map<String, dynamic>, String,
      {required bool isRevoked}) buildTileContent;
  const _CollabTileContent({
    required this.collabId,
    required this.collectionPath,
    required this.currentUserEmail,
    required this.buildTileContent,
  });
  @override
  State<_CollabTileContent> createState() => _CollabTileContentState();
}

class _CollabTileContentState extends State<_CollabTileContent> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection(widget.collectionPath)
          .doc(widget.collabId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox();
        }
        // NEW LOGIC: No revocation checks - if todo is in our list, we can interact with it
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(widget.collectionPath)
              .doc(widget.collabId)
              .snapshots(),
          builder: (context, streamSnapshot) {
            if (!streamSnapshot.hasData || !streamSnapshot.data!.exists) {
              return SizedBox();
            }
            final liveData = streamSnapshot.data!.data()!;
            return widget.buildTileContent(
                context, liveData, widget.currentUserEmail,
                isRevoked: false); // Always false - no revocation logic
          },
        );
      },
    );
  }
}

String encodeEmailForFirestore(String email) => email.replaceAll('.', '_dot_');

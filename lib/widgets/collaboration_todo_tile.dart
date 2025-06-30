import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/widgets/comment_input_field.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/spacer_widget.dart';
import '../pages/to_do_page.dart' show CommentInputField;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'collab_todo_edit_dialog.dart';
import 'package:four_secrets_wedding_app/model/to_do_model.dart';

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
  Future<String> _getOwnerName(String ownerId, String ownerName) async {
    if (ownerName.isNotEmpty) return ownerName;
    if (_cachedOwnerName != null) return _cachedOwnerName!;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
    final name = doc.data()?['name'] ?? ownerId;
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

  Widget _buildTileContent(
      BuildContext context, Map<String, dynamic> data, String currentUserId,
      {required bool isRevoked}) {
    final categories =
        List<Map<String, dynamic>>.from(data['categories'] ?? []);
    final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
    final ownerName = data['ownerName'] ?? '';
    final ownerId = data['ownerId'] ?? '';
    final todoName = data['todoName'] ?? '';
    final revokedFor = List<String>.from(data['revokedFor'] ?? []);
    final collaborators = List<String>.from(data['collaborators'] ?? []);
    final categoryName = (categories.isNotEmpty &&
            categories[0]['categoryName'] != null &&
            categories[0]['categoryName'].toString().isNotEmpty)
        ? categories[0]['categoryName']
        : todoName;
    final isOwned = currentUserId != null && ownerId == currentUserId;
    final isRevoked = !isOwned && revokedFor.contains(currentUserId);
    // Debug prints for collaboration state
    debugPrint('[CollabTile] currentUserId: $currentUserId');
    debugPrint('[CollabTile] collaborators: $collaborators');
    debugPrint('[CollabTile] revokedFor: $revokedFor');
    // --- Unread logic for comments and checkbox changes ---
    Timestamp? lastRead;
    if (data['commentReadTimestamps'] != null && currentUserId != null) {
      final map = data['commentReadTimestamps'] as Map<String, dynamic>;
      if (map[currentUserId] != null) {
        lastRead = map[currentUserId] is Timestamp
            ? map[currentUserId]
            : (map[currentUserId] is int
                ? Timestamp.fromMillisecondsSinceEpoch(map[currentUserId])
                : null);
      }
    }
    // Find latest comment not by current user
    Timestamp? latestNonCurrentUserCommentTs;
    if (comments.isNotEmpty && currentUserId != null) {
      final nonCurrentUserComments =
          comments.where((c) => c['userId'] != currentUserId).toList()
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
    // For checkbox, check lastActivityUserId
    final lastActivityUserId = data['lastActivityUserId'];
    Timestamp? lastActivityTs =
        (lastActivityUserId != null && lastActivityUserId != currentUserId)
            ? data['lastActivityTimestamp'] as Timestamp?
            : null;
    // Use the latest of these two
    Timestamp? latestTs;
    if (latestNonCurrentUserCommentTs != null && lastActivityTs != null) {
      latestTs = latestNonCurrentUserCommentTs.compareTo(lastActivityTs) > 0
          ? latestNonCurrentUserCommentTs
          : lastActivityTs;
    } else {
      latestTs = latestNonCurrentUserCommentTs ?? lastActivityTs;
    }
    bool _hasUnread = false;
    if (latestTs != null && currentUserId != null) {
      if (lastRead == null || latestTs.compareTo(lastRead) > 0) {
        _hasUnread = true;
      }
    }
    final editingController = widget.editingController;
    final labelColor = widget.labelColor;
    final labelTextColor = widget.labelTextColor;
    final avatarColor = widget.avatarColor;
    final checkboxColor = widget.checkboxColor;
    final showTag = widget.showTag;
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
            shape: OutlineInputBorder(borderSide: BorderSide.none),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        categoryName,
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                    if (isOwned) ...[
                      Expanded(
                          child: SizedBox(
                        width: 10,
                      )),
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: Color(0xFF6B456A), size: 20),
                        tooltip: 'Bearbeiten',
                        onPressed: () async {
                          // Navigate to addToDoPage with todo data
                          Navigator.of(context).pushNamed(
                            '/addToDoPage',
                            arguments: {
                              'toDoModel': ToDoModel(
                                id: widget.collabId,
                                toDoName: todoName,
                                userId: ownerId,
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
                              title: 'Todo löschen',
                              message:
                                  'Möchten Sie dieses Todo wirklich löschen?',
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
                                    context, 'Todo gelöscht');
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
                SizedBox(height: 4),
                if (showTag)
                  FutureBuilder<String>(
                    future: _getOwnerName(ownerId, ownerName),
                    builder: (context, snapshot) {
                      final displayName =
                          snapshot.hasData ? snapshot.data! : ownerId;
                      if (isOwned) {
                        return Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: labelColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomTextWidget(
                            text: 'Eigentümer',
                            color: labelTextColor,
                            fontSize: 14,
                          ),
                        );
                      } else {
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
                      }
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
                                  } catch (e) {
                                    if (context.mounted) {
                                      SnackBarHelper.showErrorSnackBar(
                                          context, "Failed to update item: $e");
                                    }
                                  }
                                },
                                activeColor: checkboxColor,
                              ),
                              SizedBox(width: 8),
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final String? commentUserId = comment['userId'];
                        return FutureBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          future: commentUserId != null
                              ? FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(commentUserId)
                                  .get()
                              : null,
                          builder: (context, userSnapshot) {
                            String? profilePicUrl;
                            if (userSnapshot.connectionState ==
                                    ConnectionState.done &&
                                userSnapshot.hasData &&
                                userSnapshot.data!.exists) {
                              final userData = userSnapshot.data!.data();
                              profilePicUrl = userData != null
                                  ? userData['profilePictureUrl'] as String?
                                  : null;
                            }
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: avatarColor,
                                        backgroundImage:
                                            (profilePicUrl != null &&
                                                    profilePicUrl.isNotEmpty)
                                                ? NetworkImage(profilePicUrl)
                                                : null,
                                        child: (profilePicUrl == null ||
                                                profilePicUrl.isEmpty)
                                            ? CustomTextWidget(
                                                text: (comment['userName'] ??
                                                    'U')[0],
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontSize: 16)
                                            : null,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment['userName'] ??
                                                  'Unbekannt',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black),
                                            ),
                                            if (comment['timestamp'] != null)
                                              Text(
                                                _formatTimestamp(
                                                    comment['timestamp']),
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (comment['userId'] == currentUserId)
                                        PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              setState(() {
                                                editingCommentIndex = index;
                                                editingComment = comment;
                                                editingController.text =
                                                    comment['comment'] ?? '';
                                                isEditingComment = true;
                                              });
                                            } else if (value == 'delete') {
                                              // Confirm before deleting
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    CustomDialog(
                                                  title: 'Kommentar löschen',
                                                  message:
                                                      'Möchten Sie diesen Kommentar wirklich löschen?',
                                                  confirmText: 'Löschen',
                                                  cancelText: 'Abbrechen',
                                                  onConfirm: () async {
                                                    Navigator.pop(
                                                        context, true);
                                                  },
                                                  onCancel: () {
                                                    Navigator.pop(
                                                        context, false);
                                                  },
                                                ),
                                              );
                                              if (confirm == true) {
                                                try {
                                                  List<Map<String, dynamic>>
                                                      updatedComments = List<
                                                              Map<String,
                                                                  dynamic>>.from(
                                                          comments);
                                                  updatedComments.removeWhere(
                                                      (c) =>
                                                          c['userId'] ==
                                                              comment[
                                                                  'userId'] &&
                                                          c['timestamp'] ==
                                                              comment[
                                                                  'timestamp'] &&
                                                          c['comment'] ==
                                                              comment[
                                                                  'comment']);
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          widget.collectionPath)
                                                      .doc(widget.collabId)
                                                      .update({
                                                    'comments': updatedComments
                                                  });
                                                  if (context.mounted) {
                                                    SnackBarHelper
                                                        .showSuccessSnackBar(
                                                            context,
                                                            'Kommentar gelöscht');
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    SnackBarHelper
                                                        .showErrorSnackBar(
                                                            context,
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
                                                  Icon(Icons.edit,
                                                      color: Color(0xFF6B456A),
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  CustomTextWidget(
                                                      color: Color(0xFF6B456A),
                                                      text: 'Bearbeiten'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      FontAwesomeIcons.trashCan,
                                                      color: Colors.red,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  CustomTextWidget(
                                                      color: Colors.red,
                                                      text: 'Löschen'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 4.0),
                                    child: CustomTextWidget(
                                      text: comment['comment'] ?? '',
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
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
              if (expanded && currentUserId != null && latestTs != null) {
                // Mark as read: update last read timestamp to latest activity
                await FirebaseFirestore.instance
                    .collection(widget.collectionPath)
                    .doc(widget.collabId)
                    .update({'commentReadTimestamps.$currentUserId': latestTs});
              }
            },
          ),
          // Unified add/edit comment box always visible below the tile
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: CommentInputField(
              collabId: widget.collabId,
              controller: editingController,
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
                        editingController.clear();
                        isEditingComment = false;
                      });
                    }
                  : null,
              onCancel: isEditingComment
                  ? () {
                      setState(() {
                        editingCommentIndex = null;
                        editingComment = null;
                        editingController.clear();
                        isEditingComment = false;
                      });
                    }
                  : null,
              onSend: (value) async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                final newComment = {
                  'userId': user.uid,
                  'userName': user.displayName ?? 'Unbekannt',
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
              },
              enabled: isOwned ||
                  (!isRevoked &&
                      collaborators.isNotEmpty &&
                      collaborators.contains(currentUserId)),
            ),
          ),
          SpacerWidget(height: 3),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Debug print for collabId and collectionPath
    debugPrint('[CollaborationTodoTile] collabId: '
        '\x1B[33m${widget.collabId}\x1B[0m, '
        'collectionPath: \x1B[32m${widget.collectionPath}\x1B[0m');
    // Use static snapshot for revoked users, real-time for others
    return Builder(
      builder: (context) {
        if (currentUserId == null) return SizedBox();
        // Use a FutureBuilder for revoked users (static), StreamBuilder for others (live)
        return _CollabTileContent(
          collabId: widget.collabId,
          collectionPath: widget.collectionPath,
          currentUserId: currentUserId,
          buildTileContent: _buildTileContent,
        );
      },
    );
  }
}

class _CollabTileContent extends StatefulWidget {
  final String collabId;
  final String collectionPath;
  final String currentUserId;
  final Widget Function(BuildContext, Map<String, dynamic>, String,
      {required bool isRevoked}) buildTileContent;
  const _CollabTileContent({
    required this.collabId,
    required this.collectionPath,
    required this.currentUserId,
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
        final data = snapshot.data!.data()!;
        final revokedFor = List<String>.from(data['revokedFor'] ?? []);
        final isOwned = data['ownerId'] == widget.currentUserId;
        final isRevoked = !isOwned && revokedFor.contains(widget.currentUserId);
        if (isRevoked) {
          return widget.buildTileContent(context, data, widget.currentUserId,
              isRevoked: true);
        } else {
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
                  context, liveData, widget.currentUserId,
                  isRevoked: false);
            },
          );
        }
      },
    );
  }
}

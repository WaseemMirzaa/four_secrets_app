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

class CollaborationTodoTile extends StatefulWidget {
  final String collabId;
  final Color color;
  final Color labelColor;
  final Color labelTextColor;
  final Color checkboxColor;
  final Color avatarColor;

  CollaborationTodoTile({
    Key? key,
    required this.collabId,
    required this.color,
    required this.labelColor,
    required this.labelTextColor,
    required this.checkboxColor,
    required this.avatarColor,
  }) : super(key: key);

  final TextEditingController editingController = TextEditingController();

  @override
  State<CollaborationTodoTile> createState() => _CollaborationTodoTileState();
}

class _CollaborationTodoTileState extends State<CollaborationTodoTile> {
  int? editingCommentIndex;
  Map<String, dynamic>? editingComment;
  bool isEditingComment = false;
  bool _isExpanded = false;

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

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('collaboration_todos')
          .doc(widget.collabId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox();
        }
        final data = snapshot.data!.data()!;
        final categories =
            List<Map<String, dynamic>>.from(data['categories'] ?? []);
        final comments =
            List<Map<String, dynamic>>.from(data['comments'] ?? []);
        final ownerName = data['ownerName'] ?? '';
        final ownerId = data['ownerId'] ?? '';
        final todoName = data['todoName'] ?? '';
        final categoryName = (categories.isNotEmpty &&
                categories[0]['categoryName'] != null &&
                categories[0]['categoryName'].toString().isNotEmpty)
            ? categories[0]['categoryName']
            : todoName;
        final isOwned = currentUserId != null && ownerId == currentUserId;
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
        // Find latest activity: comment or checkbox
        Timestamp? latestCommentTs;
        if (comments.isNotEmpty) {
          final sorted = List<Map<String, dynamic>>.from(comments)
            ..sort((a, b) {
              final ta = a['timestamp'];
              final tb = b['timestamp'];
              if (ta is Timestamp && tb is Timestamp) {
                return tb.compareTo(ta);
              }
              return 0;
            });
          latestCommentTs = sorted.first['timestamp'] as Timestamp?;
        }
        Timestamp? lastActivityTs = data['lastActivityTimestamp'] as Timestamp?;
        // Use the latest of comment or lastActivityTimestamp
        Timestamp? latestTs;
        if (latestCommentTs != null && lastActivityTs != null) {
          latestTs = latestCommentTs.compareTo(lastActivityTs) > 0
              ? latestCommentTs
              : lastActivityTs;
        } else {
          latestTs = latestCommentTs ?? lastActivityTs;
        }
        bool _hasUnread = false;
        if (latestTs != null && currentUserId != null) {
          if (lastRead == null || latestTs.compareTo(lastRead) > 0) {
            _hasUnread = true;
          }
        }
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: widget.color,
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          categoryName,
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.labelColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomTextWidget(
                        text: isOwned
                            ? 'Eigentümer'
                            : 'Geteilt von ${ownerName.isNotEmpty ? ownerName : ownerId}',
                        color: widget.labelTextColor,
                        fontSize: 14,
                      ),
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
                                        final now = Timestamp.now();
                                        await FirebaseFirestore.instance
                                            .collection('collaboration_todos')
                                            .doc(widget.collabId)
                                            .update({
                                          'categories': categoriesCopy,
                                          'lastActivityTimestamp': now,
                                        });
                                      } catch (e) {
                                        if (context.mounted) {
                                          SnackBarHelper.showErrorSnackBar(
                                              context,
                                              "Failed to update item: $e");
                                        }
                                      }
                                    },
                                    activeColor: widget.checkboxColor,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: widget.avatarColor,
                                            backgroundImage: (profilePicUrl !=
                                                        null &&
                                                    profilePicUrl.isNotEmpty)
                                                ? NetworkImage(profilePicUrl)
                                                : null,
                                            child: (profilePicUrl == null ||
                                                    profilePicUrl.isEmpty)
                                                ? CustomTextWidget(
                                                    text:
                                                        (comment['userName'] ??
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black),
                                                ),
                                                if (comment['timestamp'] !=
                                                    null)
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
                                          if (comment['userId'] ==
                                              currentUserId)
                                            PopupMenuButton<String>(
                                              onSelected: (value) async {
                                                if (value == 'edit') {
                                                  setState(() {
                                                    editingCommentIndex = index;
                                                    editingComment = comment;
                                                    widget.editingController
                                                            .text =
                                                        comment['comment'] ??
                                                            '';
                                                    isEditingComment = true;
                                                  });
                                                } else if (value == 'delete') {
                                                  // Confirm before deleting
                                                  final confirm =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        CustomDialog(
                                                      title:
                                                          'Kommentar löschen',
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
                                                          updatedComments =
                                                          List<
                                                                  Map<String,
                                                                      dynamic>>.from(
                                                              comments);
                                                      updatedComments.removeWhere((c) =>
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
                                                              'collaboration_todos')
                                                          .doc(widget.collabId)
                                                          .update({
                                                        'comments':
                                                            updatedComments
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
                                                          color:
                                                              Color(0xFF6B456A),
                                                          size: 18),
                                                      SizedBox(width: 8),
                                                      CustomTextWidget(
                                                          color:
                                                              Color(0xFF6B456A),
                                                          text: 'Bearbeiten'),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                          FontAwesomeIcons
                                                              .trashCan,
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
                        .collection('collaboration_todos')
                        .doc(widget.collabId)
                        .update(
                            {'commentReadTimestamps.$currentUserId': latestTs});
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
                                  c['timestamp'] ==
                                      editingComment!['timestamp'] &&
                                  c['comment'] == editingComment!['comment']);
                              if (idx != -1) {
                                updatedComments[idx] = {
                                  ...updatedComments[idx],
                                  'comment': result,
                                };
                                await FirebaseFirestore.instance
                                    .collection('collaboration_todos')
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
                  // onSend for add is handled by default in CommentInputField
                ),
              ),
              SpacerWidget(height: 3),
            ],
          ),
        );
      },
    );
  }
}

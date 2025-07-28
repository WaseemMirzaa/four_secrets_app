// Do we need further?

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
// import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
// import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
// import 'package:four_secrets_wedding_app/services/todo_service.dart';
// import 'package:four_secrets_wedding_app/model/to_do_model.dart';

// class CollaboratorDetailsScreen extends StatefulWidget {
//   final String todoId;
//   final String todoName;
//   final String inviteeName;
//   const CollaboratorDetailsScreen(
//       {Key? key,
//       required this.todoId,
//       required this.todoName,
//       required this.inviteeName})
//       : super(key: key);

//   @override
//   State<CollaboratorDetailsScreen> createState() =>
//       _CollaboratorDetailsScreenState();
// }

// class _CollaboratorDetailsScreenState extends State<CollaboratorDetailsScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final TextEditingController _commentController = TextEditingController();
//   final CollaborationTodoService _collaborationTodoService =
//       CollaborationTodoService();
//   final TodoService _todoService = TodoService();
//   bool _isAddingComment = false;
//   bool _isEditingComment = false;
//   String? _editingCommentId;

//   @override
//   void dispose() {
//     _commentController.dispose();
//     super.dispose();
//   }

//   Future<void> _addOrUpdateComment(String todoDocId,
//       List<Map<String, dynamic>> comments, String comment) async {
//     setState(() => _isAddingComment = true);
//     try {
//       final currentUser = _auth.currentUser;
//       if (currentUser == null) return;
//       final userDoc =
//           await _firestore.collection('users').doc(currentUser.uid).get();
//       final userName = userDoc.data()?['name'] ?? 'Unknown';

//       await _firestore.runTransaction((transaction) async {
//         final docRef =
//             _firestore.collection('collaboration_todos').doc(todoDocId);
//         final snapshot = await transaction.get(docRef);
//         if (!snapshot.exists) return;
//         final data = snapshot.data()!;
//         final currentComments =
//             List<Map<String, dynamic>>.from(data['comments'] ?? []);

//         if (_isEditingComment && _editingCommentId != null) {
//           final commentIndex = currentComments.indexWhere(
//               (c) => (c['id']?.toString() ?? '') == _editingCommentId);
//           if (commentIndex != -1) {
//             currentComments[commentIndex] = {
//               ...currentComments[commentIndex],
//               'comment': comment,
//               'editedAt': Timestamp.now(),
//             };
//           }
//         } else {
//           final newComment = {
//             'id': DateTime.now().millisecondsSinceEpoch.toString(),
//             'userId': currentUser.uid,
//             'userName': userName,
//             'comment': comment,
//             'timestamp': Timestamp.now(),
//           };
//           currentComments.add(newComment);
//         }
//         transaction.update(docRef, {'comments': currentComments});
//       });

//       setState(() {
//         _isEditingComment = false;
//         _editingCommentId = null;
//       });
//       _commentController.clear();
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//             content:
//                 Text('Fehler beim Hinzufügen/Bearbeiten des Kommentars: $e')));
//       }
//     } finally {
//       if (mounted) setState(() => _isAddingComment = false);
//     }
//   }

//   Future<void> _deleteComment(String todoDocId,
//       List<Map<String, dynamic>> comments, String commentId) async {
//     try {
//       comments.removeWhere(
//           (comment) => (comment['id']?.toString() ?? '') == commentId);
//       await _firestore
//           .collection('collaboration_todos')
//           .doc(todoDocId)
//           .update({'comments': comments});

//       setState(() {});
//       if (mounted) {
//         SnackBar(content: Text('Kommentar erfolgreich gelöscht'));
//       }
//     } catch (e) {
//       if (mounted) {
//         SnackBar(content: Text('Fehler beim Löschen des Kommentars: $e'));
//       }
//     }
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp == null) return '';
//     DateTime dateTime;
//     if (timestamp is Timestamp) {
//       dateTime = timestamp.toDate();
//     } else if (timestamp is DateTime) {
//       dateTime = timestamp;
//     } else if (timestamp is String) {
//       dateTime = DateTime.parse(timestamp);
//     } else {
//       return '';
//     }
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);
//     if (difference.inDays > 7) {
//       return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
//     } else if (difference.inDays > 0) {
//       return 'vor ${difference.inDays} Tagen';
//     } else if (difference.inHours > 0) {
//       return 'vor ${difference.inHours} Stunden';
//     } else if (difference.inMinutes > 0) {
//       return 'vor ${difference.inMinutes} Minuten';
//     } else {
//       return 'Gerade eben';
//     }
//   }

//   Future<void> _updateTodoItemChecked(String docId,
//       List<Map<String, dynamic>> toDoItems, int index, bool? value) async {
//     if (value == null) return;
//     final updatedItems = List<Map<String, dynamic>>.from(toDoItems);
//     updatedItems[index] = {
//       ...updatedItems[index],
//       'isChecked': value,
//     };
//     // Update in collaboration_todos
//     await _collaborationTodoService.updateTodoItems(docId, updatedItems);
//     // Also update in the main todos collection (owner's todo)
//     try {
//       // Fetch the collaboration_todo document to get the ownerId
//       final collabDoc =
//           await _firestore.collection('collaboration_todos').doc(docId).get();
//       final collabData = collabDoc.data() as Map<String, dynamic>?;
//       final ownerId =
//           collabData != null ? collabData['ownerId'] as String? : null;
//       if (ownerId != null && ownerId.isNotEmpty) {
//         // Fetch the main todo from the owner's collection
//         final mainTodoDoc = await _firestore
//             .collection('users')
//             .doc(ownerId)
//             .collection('todos')
//             .doc(widget.todoId)
//             .get();
//         if (mainTodoDoc.exists) {
//           final mainTodo = ToDoModel.fromFirestore(mainTodoDoc);
//           final mainItems =
//               List<Map<String, dynamic>>.from(mainTodo.toDoItems ?? []);
//           // Find the item by name (sync by name)
//           final mainIndex = mainItems.indexWhere(
//               (item) => item['name'] == updatedItems[index]['name']);
//           if (mainIndex != -1) {
//             mainItems[mainIndex] = {
//               ...mainItems[mainIndex],
//               'isChecked': value,
//             };
//             final updatedMainTodo = mainTodo.copyWith(toDoItems: mainItems);
//             await _firestore
//                 .collection('users')
//                 .doc(ownerId)
//                 .collection('todos')
//                 .doc(widget.todoId)
//                 .update(updatedMainTodo.toMap());
//           }
//         }
//       }
//     } catch (e) {
//       // Optionally show error or log
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           foregroundColor: Colors.white,
//           backgroundColor: const Color.fromARGB(255, 107, 69, 106),
//           title: CustomTextWidget(
//             text: widget.todoName,
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//           leading: BackButton(),
//           actions: [
//             StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//               stream: _firestore
//                   .collection('collaboration_todos')
//                   .where('todoId', isEqualTo: widget.todoId)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return SizedBox.shrink();
//                 }
//                 final data = snapshot.data!.docs.first.data();
//                 final ownerId = data['ownerId'];
//                 final currentUserId = _auth.currentUser?.uid;
//                 if (ownerId == currentUserId) {
//                   return IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.white),
//                     tooltip: 'Collab Todo löschen',
//                     onPressed: () async {
//                       final confirm = await showDialog<bool>(
//                         context: context,
//                         barrierDismissible: false,
//                         builder: (context) => Dialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(24.0),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 const Text(
//                                   'Löschen bestätigen',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 const Text(
//                                   'Möchtest du dieses Collaboration Todo wirklich löschen?',
//                                   textAlign: TextAlign.center,
//                                 ),
//                                 const SizedBox(height: 24),
//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: CustomButtonWidget(
//                                         text: 'Abbrechen',
//                                         color: Colors.white,
//                                         textColor: Colors.black,
//                                         onPressed: () =>
//                                             Navigator.of(context).pop(false),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 16),
//                                     Expanded(
//                                       child: CustomButtonWidget(
//                                         text: 'Löschen',
//                                         color: Colors.red,
//                                         textColor: Colors.white,
//                                         onPressed: () =>
//                                             Navigator.of(context).pop(true),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                       if (confirm == true) {
//                         // Get the collaboration todo docId
//                         final docId = snapshot.data!.docs.first.id;

//                         // Query the invitations
//                         final invitationsSnapshot = await _firestore
//                             .collection('invitations')
//                             .where('todoId', isEqualTo: widget.todoId)
//                             .get();

//                         // Start a batch
//                         final batch = _firestore.batch();

//                         // Add delete operations for invitations
//                         for (var doc in invitationsSnapshot.docs) {
//                           batch.delete(doc.reference);
//                         }

//                         // Add delete operation for collaboration todo
//                         batch.delete(_firestore
//                             .collection('collaboration_todos')
//                             .doc(docId));

//                         // Commit the batch
//                         await batch.commit();

//                         if (mounted) Navigator.of(context).pop(true);
//                       }
//                     },
//                   );
//                 }
//                 return SizedBox.shrink();
//               },
//             ),
//           ],
//         ),
//         body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//           stream: _firestore
//               .collection('collaboration_todos')
//               .where('todoId', isEqualTo: widget.todoId)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             // Debug: Print snapshot data
//             print(
//                 'CollabDetailsScreen snapshot: \\nHasData: \\${snapshot.hasData}, Docs: \\${snapshot.data?.docs.length}');
//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               // Instead of popping, show a visible message
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.info_outline, size: 48, color: Colors.grey),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Keine Details gefunden.\nBitte überprüfe, ob die Zusammenarbeit noch existiert.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               );
//             }
//             final doc = snapshot.data!.docs.first;
//             final data = doc.data();
//             final toDoItems =
//                 List<Map<String, dynamic>>.from(data['toDoItems'] ?? []);
//             final comments =
//                 List<Map<String, dynamic>>.from(data['comments'] ?? []);
//             return Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(widget.todoName,
//                       style: const TextStyle(
//                           fontSize: 22, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 12),
//                   Text('Aufgaben:',
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 16)),
//                   ...toDoItems.asMap().entries.map((entry) {
//                     final index = entry.key;
//                     final item = entry.value;
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 4.0),
//                       child: Row(
//                         children: [
//                           Checkbox(
//                             value: item['isChecked'] ?? false,
//                             onChanged: (bool? value) async {
//                               await _updateTodoItemChecked(
//                                   doc.id, toDoItems, index, value);
//                             },
//                             activeColor:
//                                 const Color.fromARGB(255, 107, 69, 106),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               item['name'] ?? '',
//                               style: TextStyle(
//                                 decoration: (item['isChecked'] ?? false)
//                                     ? TextDecoration.lineThrough
//                                     : null,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }),
//                   const SizedBox(height: 20),
//                   Text('Kommentare:',
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 16)),
//                   const SizedBox(height: 8),
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: comments.length,
//                       itemBuilder: (context, index) {
//                         final comment = comments[index];
//                         return Container(
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade200,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           padding: const EdgeInsets.all(12.0),
//                           margin: const EdgeInsets.symmetric(vertical: 6.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 18,
//                                     backgroundColor: Colors.grey.shade400,
//                                     child: Text(
//                                       (comment['userName'] ?? 'U')[0],
//                                       style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           comment['userName'] ?? 'Unbekannt',
//                                           style: const TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.black),
//                                         ),
//                                         if (comment['timestamp'] != null)
//                                           Text(
//                                             _formatTimestamp(
//                                                 comment['timestamp']),
//                                             style: const TextStyle(
//                                                 color: Colors.black,
//                                                 fontSize: 12),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                   if (comment['userId'] ==
//                                       _auth.currentUser?.uid)
//                                     PopupMenuButton<String>(
//                                       icon: const Icon(Icons.more_vert,
//                                           size: 20, color: Colors.black),
//                                       onSelected: (value) {
//                                         if (value == 'edit') {
//                                           setState(() {
//                                             _commentController.text =
//                                                 comment['comment'] ?? '';
//                                             _editingCommentId =
//                                                 comment['id']?.toString();
//                                             _isEditingComment = true;
//                                           });
//                                         } else if (value == 'delete') {
//                                           _deleteComment(doc.id, comments,
//                                               comment['id']?.toString() ?? '');
//                                         }
//                                       },
//                                       itemBuilder: (context) => [
//                                         const PopupMenuItem(
//                                           value: 'edit',
//                                           child: Row(
//                                             children: [
//                                               Icon(Icons.edit,
//                                                   size: 20,
//                                                   color: Colors.black),
//                                               SizedBox(width: 8),
//                                               Text('Bearbeiten'),
//                                             ],
//                                           ),
//                                         ),
//                                         const PopupMenuItem(
//                                           value: 'delete',
//                                           child: Row(
//                                             children: [
//                                               Icon(Icons.delete,
//                                                   size: 20, color: Colors.red),
//                                               SizedBox(width: 8),
//                                               Text('Löschen',
//                                                   style: TextStyle(
//                                                       color: Colors.red)),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                 ],
//                               ),
//                               const SizedBox(height: 4),
//                               Padding(
//                                 padding: const EdgeInsets.only(left: 48.0),
//                                 child: Text(
//                                   comment['comment'] ?? '',
//                                   style: const TextStyle(
//                                       fontSize: 13, color: Colors.black),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: _commentController,
//                           decoration: InputDecoration(
//                             hintText: _isEditingComment
//                                 ? 'Kommentar bearbeiten...'
//                                 : 'Kommentar hinzufügen...',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 12),
//                           ),
//                           maxLines: 1,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       _isAddingComment
//                           ? const SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             )
//                           : IconButton(
//                               icon: Icon(Icons.send,
//                                   color: Theme.of(context).primaryColor),
//                               onPressed: () async {
//                                 final comment = _commentController.text.trim();
//                                 if (comment.isNotEmpty) {
//                                   await _addOrUpdateComment(
//                                       doc.id, comments, comment);
//                                 }
//                               },
//                             ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class CollaborationTodoModel {
  final String id;
  final String todoId;
  final String todoName;
  final String ownerId;
  final String ownerName;
  final List<String> collaborators;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> toDoItems;
  final DateTime createdAt;
  final DateTime? lastModified;

  CollaborationTodoModel({
    required this.id,
    required this.todoId,
    required this.todoName,
    required this.ownerId,
    required this.ownerName,
    required this.collaborators,
    required this.comments,
    required this.toDoItems,
    required this.createdAt,
    this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'todoId': todoId,
      'todoName': todoName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'collaborators': collaborators,
      'comments': comments,
      'toDoItems': toDoItems,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified':
          lastModified != null ? Timestamp.fromDate(lastModified!) : null,
    };
  }

  factory CollaborationTodoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert toDoItems to the correct format
    List<Map<String, dynamic>> processedToDoItems = [];
    if (data['toDoItems'] != null) {
      final rawItems = data['toDoItems'];
      if (rawItems is List) {
        processedToDoItems = rawItems.map((item) {
          if (item is String) {
            return {'name': item, 'isChecked': false};
          } else if (item is Map<String, dynamic>) {
            return {
              'name': item['name'] ?? '',
              'isChecked': item['isChecked'] ?? false
            };
          } else {
            return {'name': item.toString(), 'isChecked': false};
          }
        }).toList();
      }
    }

    return CollaborationTodoModel(
      id: doc.id,
      todoId: data['todoId'] ?? '',
      todoName: data['todoName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      collaborators: List<String>.from(data['collaborators'] ?? []),
      comments: List<Map<String, dynamic>>.from(data['comments'] ?? []),
      toDoItems: processedToDoItems,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
    );
  }

  CollaborationTodoModel copyWith({
    String? id,
    String? todoId,
    String? todoName,
    String? ownerId,
    String? ownerName,
    List<String>? collaborators,
    List<Map<String, dynamic>>? comments,
    List<Map<String, dynamic>>? toDoItems,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return CollaborationTodoModel(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      todoName: todoName ?? this.todoName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      collaborators: collaborators ?? this.collaborators,
      comments: comments ?? this.comments,
      toDoItems: toDoItems ?? this.toDoItems,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  // Add a comment to the collaboration todo
  CollaborationTodoModel addComment(
      String userId, String userName, String comment) {
    final newComment = {
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'timestamp': DateTime.now(),
    };

    final updatedComments = List<Map<String, dynamic>>.from(comments)
      ..add(newComment);

    return copyWith(
      comments: updatedComments,
      lastModified: DateTime.now(),
    );
  }

  // Add a collaborator to the collaboration todo
  CollaborationTodoModel addCollaborator(String collaboratorId) {
    if (!collaborators.contains(collaboratorId)) {
      final updatedCollaborators = List<String>.from(collaborators)
        ..add(collaboratorId);
      return copyWith(
        collaborators: updatedCollaborators,
        lastModified: DateTime.now(),
      );
    }
    return this;
  }

  // Remove a collaborator from the collaboration todo
  CollaborationTodoModel removeCollaborator(String collaboratorId) {
    if (collaborators.contains(collaboratorId)) {
      final updatedCollaborators = List<String>.from(collaborators)
        ..remove(collaboratorId);
      return copyWith(
        collaborators: updatedCollaborators,
        lastModified: DateTime.now(),
      );
    }
    return this;
  }
}

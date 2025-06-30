import 'package:cloud_firestore/cloud_firestore.dart';

class ToDoModel {
  final String? id;
  final String? toDoName;
  final String userId;
  final String? ownerEmail;
  final String? categoryId;
  final List<String> collaborators;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>>? toDoItems;
  final String? reminder; // ISO8601 string or null
  final List<Map<String, dynamic>>? categories; // New: multi-category support
  final bool isShared;
  final List<String> revokedFor;

  ToDoModel({
    this.id,
    this.toDoName,
    required this.userId,
    this.ownerEmail,
    this.categoryId,
    required this.collaborators,
    required this.comments,
    this.toDoItems,
    this.reminder,
    this.categories, // New
    this.isShared = false,
    this.revokedFor = const [],
  });

  factory ToDoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert string items to maps with checked state if needed
    List<Map<String, dynamic>>? convertedItems;
    var rawItems = data['toDoItems'];
    if (rawItems is List) {
      convertedItems = rawItems.map((item) {
        if (item is String) {
          return {'name': item, 'isChecked': false};
        } else if (item is Map<String, dynamic>) {
          return item;
        }
        return {'name': item.toString(), 'isChecked': false};
      }).toList();
    }

    // New: categories
    List<Map<String, dynamic>>? categories;
    if (data['categories'] != null && data['categories'] is List) {
      categories = List<Map<String, dynamic>>.from(
        (data['categories'] as List)
            .map((cat) => Map<String, dynamic>.from(cat)),
      );
    }

    return ToDoModel(
      id: doc.id,
      toDoName: data['toDoName'],
      userId: data['userId'] ?? '',
      ownerEmail: data['ownerEmail'],
      categoryId: data['categoryId'],
      collaborators: List<String>.from(data['collaborators'] ?? []),
      comments: List<Map<String, dynamic>>.from(data['comments'] ?? []),
      toDoItems: convertedItems,
      reminder: data['reminder'],
      categories: categories,
      isShared: data['isShared'] ?? false,
      revokedFor: List<String>.from(data['revokedFor'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'userId': userId,
      if (categoryId != null) 'categoryId': categoryId,
      'collaborators': collaborators,
      'comments': comments,
      if (toDoName != null) 'toDoName': toDoName,
      if (toDoItems != null) 'toDoItems': toDoItems,
      if (reminder != null) 'reminder': reminder,
      'isShared': isShared,
      'revokedFor': revokedFor,
    };
    if (categories != null) {
      map['categories'] = categories;
    }
    return map;
  }

  ToDoModel copyWith({
    String? id,
    String? toDoName,
    String? userId,
    String? ownerEmail,
    String? categoryId,
    List<String>? collaborators,
    List<Map<String, dynamic>>? comments,
    List<Map<String, dynamic>>? toDoItems,
    String? reminder,
    List<Map<String, dynamic>>? categories, // New
    bool? isShared,
    List<String>? revokedFor,
  }) {
    return ToDoModel(
      id: id ?? this.id,
      toDoName: toDoName ?? this.toDoName,
      userId: userId ?? this.userId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      categoryId: categoryId ?? this.categoryId,
      collaborators: collaborators ?? this.collaborators,
      comments: comments ?? this.comments,
      toDoItems: toDoItems ?? this.toDoItems,
      reminder: reminder ?? this.reminder,
      categories: categories ?? this.categories,
      isShared: isShared ?? this.isShared,
      revokedFor: revokedFor ?? this.revokedFor,
    );
  }

  // Add a comment to the todo list
  ToDoModel addComment(String userId, String userName, String comment) {
    final newComment = {
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'timestamp': DateTime.now(),
    };

    final updatedComments = List<Map<String, dynamic>>.from(comments)
      ..add(newComment);

    return copyWith(comments: updatedComments);
  }

  // Add a collaborator to the todo list
  ToDoModel addCollaborator(String collaboratorId) {
    if (!collaborators.contains(collaboratorId)) {
      final updatedCollaborators = List<String>.from(collaborators)
        ..add(collaboratorId);
      return copyWith(collaborators: updatedCollaborators);
    }
    return this;
  }

  // Remove a collaborator from the todo list
  ToDoModel removeCollaborator(String collaboratorId) {
    if (collaborators.contains(collaboratorId)) {
      final updatedCollaborators = List<String>.from(collaborators)
        ..remove(collaboratorId);
      return copyWith(collaborators: updatedCollaborators);
    }
    return this;
  }

  // Toggle item checked state
  ToDoModel toggleItemChecked(String itemName) {
    final updatedItems = List<Map<String, dynamic>>.from(toDoItems ?? []);
    final itemIndex =
        updatedItems.indexWhere((item) => item['name'] == itemName);
    if (itemIndex != -1) {
      updatedItems[itemIndex] = {
        ...updatedItems[itemIndex],
        'isChecked': !(updatedItems[itemIndex]['isChecked'] ?? false),
      };
      return copyWith(toDoItems: updatedItems);
    }
    return this;
  }
}

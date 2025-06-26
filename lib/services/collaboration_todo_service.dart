import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/collaboration_todo_model.dart';
import 'push_notification_service.dart';

class CollaborationTodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PushNotificationService _pushNotificationService =
      PushNotificationService();

  String? get userId => _auth.currentUser?.uid;

  // Create a new collaboration todo
  Future<CollaborationTodoModel> createCollaborationTodo({
    required String todoId,
    required String todoName,
    required String ownerId,
    required String ownerName,
    required List<Map<String, dynamic>> toDoItems,
    List<Map<String, dynamic>> comments = const [],
    List<Map<String, dynamic>>? categories,
    String? collaboratorId,
  }) async {
    if (userId == null && collaboratorId == null) {
      throw Exception('User not logged in');
    }

    final docRef = _firestore.collection('collaboration_todos').doc();

    final todo = CollaborationTodoModel(
      id: docRef.id,
      todoId: todoId,
      todoName: todoName,
      ownerId: ownerId,
      ownerName: ownerName,
      collaborators: [collaboratorId ?? userId!],
      comments: comments,
      toDoItems: toDoItems,
      createdAt: DateTime.now(),
      categories: categories,
    );

    await docRef.set(todo.toMap());
    return todo;
  }

  // Get all collaboration todos for the current user
  Future<List<CollaborationTodoModel>> getCollaborationTodos() async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      // Get todos where user is a collaborator
      final snapshot = await _firestore
          .collection('collaboration_todos')
          .where('collaborators', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => CollaborationTodoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting collaboration todos: $e');
      throw Exception('Failed to get collaboration todos: $e');
    }
  }

  // Get a specific collaboration todo
  Future<CollaborationTodoModel?> getCollaborationTodo(String todoId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final doc =
          await _firestore.collection('collaboration_todos').doc(todoId).get();

      if (!doc.exists) {
        return null;
      }

      return CollaborationTodoModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting collaboration todo: $e');
      throw Exception('Failed to get collaboration todo: $e');
    }
  }

  // Add a comment to a collaboration todo
  Future<void> addComment(String todoId, String comment) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      // Get current user's name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      // Get the todo
      final todoDoc =
          await _firestore.collection('collaboration_todos').doc(todoId).get();

      if (!todoDoc.exists) {
        throw Exception('Todo not found');
      }

      final todo = CollaborationTodoModel.fromFirestore(todoDoc);
      final updatedTodo = todo.addComment(userId!, userName, comment);

      // Update the todo
      await todoDoc.reference.update(updatedTodo.toMap());

      // Send push notification to the todo owner, but not if the owner is the commenter
      if (todo.ownerId != userId) {
        await _pushNotificationService.sendCommentNotification(
          todoOwnerId: todo.ownerId,
          commenterName: userName,
          todoName: todo.todoName,
          comment: comment,
        );
      }
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  // Add a collaborator to a collaboration todo
  Future<void> addCollaborator(String todoId, String collaboratorId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final todoDoc =
          await _firestore.collection('collaboration_todos').doc(todoId).get();

      if (!todoDoc.exists) {
        throw Exception('Todo not found');
      }

      final todo = CollaborationTodoModel.fromFirestore(todoDoc);
      if (todo.ownerId != userId) {
        throw Exception('Only the owner can add collaborators');
      }

      final updatedTodo = todo.addCollaborator(collaboratorId);
      await todoDoc.reference.update(updatedTodo.toMap());
    } catch (e) {
      print('Error adding collaborator: $e');
      throw Exception('Failed to add collaborator: $e');
    }
  }

  // Remove a collaborator from a collaboration todo
  Future<void> removeCollaborator(String todoId, String collaboratorId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final todoDoc =
          await _firestore.collection('collaboration_todos').doc(todoId).get();

      if (!todoDoc.exists) {
        throw Exception('Todo not found');
      }

      final todo = CollaborationTodoModel.fromFirestore(todoDoc);
      if (todo.ownerId != userId) {
        throw Exception('Only the owner can remove collaborators');
      }

      final updatedTodo = todo.removeCollaborator(collaboratorId);
      await todoDoc.reference.update(updatedTodo.toMap());
    } catch (e) {
      print('Error removing collaborator: $e');
      throw Exception('Failed to remove collaborator: $e');
    }
  }

  // Leave a collaboration todo
  Future<void> leaveCollaboration(String todoId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final todoDoc =
          await _firestore.collection('collaboration_todos').doc(todoId).get();

      if (!todoDoc.exists) {
        throw Exception('Todo not found');
      }

      final todo = CollaborationTodoModel.fromFirestore(todoDoc);
      if (todo.ownerId == userId) {
        throw Exception('Owner cannot leave their own todo');
      }

      final updatedTodo = todo.removeCollaborator(userId!);
      await todoDoc.reference.update(updatedTodo.toMap());
    } catch (e) {
      print('Error leaving collaboration: $e');
      throw Exception('Failed to leave collaboration: $e');
    }
  }

  // Delete a collaboration todo
  Future<void> deleteCollaborationTodo(String todoId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final todoDoc =
          await _firestore.collection('collaboration_todos').doc(todoId).get();

      if (!todoDoc.exists) {
        print('Todo not found, might have been already deleted');
        return;
      }

      final todo = CollaborationTodoModel.fromFirestore(todoDoc);

      // Only allow deletion if user is the owner
      if (todo.ownerId != userId) {
        throw Exception('Only the owner can delete the todo');
      }

      // Delete the collaboration todo
      await todoDoc.reference.delete();

      print('Successfully deleted collaboration todo: $todoId');
    } catch (e) {
      print('Error deleting collaboration todo: $e');
      throw Exception('Failed to delete collaboration todo: $e');
    }
  }

  // Update todo items in a collaboration todo
  Future<void> updateTodoItems(
      String todoId, List<Map<String, dynamic>> toDoItems) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final todoDoc =
          await _firestore.collection('collaboration_todos').doc(todoId).get();

      if (!todoDoc.exists) {
        throw Exception('Todo not found');
      }

      final todo = CollaborationTodoModel.fromFirestore(todoDoc);
      final updatedTodo = todo.copyWith(
        toDoItems: toDoItems,
        lastModified: DateTime.now(),
      );

      await todoDoc.reference.update(updatedTodo.toMap());
    } catch (e) {
      print('Error updating todo items: $e');
      throw Exception('Failed to update todo items: $e');
    }
  }
}

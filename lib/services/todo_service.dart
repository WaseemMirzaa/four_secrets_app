import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/to_do_model.dart';
import 'collaboration_service.dart';
import 'category_service.dart';

class TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollaborationService _collaborationService = CollaborationService();
  final CategoryService _categoryService = CategoryService();

  String? get userId => _auth.currentUser?.uid;

  // // Create initial data for first-time users
  // Future<void> createInitialTodoItems() async {
  //   print('🟢 Starting createInitialTodoItems');
  //   if (userId == null) {
  //     print('🔴 Cannot create initial data: User not logged in');
  //     throw Exception('User not logged in');
  //   }
  //   print('🟢 User ID: $userId');

  //   // First check if user document exists
  //   final userDoc = await _firestore.collection('users').doc(userId).get();
  //   print('🟢 User document exists: ${userDoc.exists}');

  //   // If user document doesn't exist, create it with an initialization flag
  //   if (!userDoc.exists) {
  //     print('🟢 Creating new user document');
  //     await _firestore.collection('users').doc(userId).set({
  //       'todoInitialized': false,
  //     });
  //   }

  //   // Get the user document (it definitely exists now)
  //   final userData =
  //       (await _firestore.collection('users').doc(userId).get()).data();
  //   print('🟢 User data retrieved: ${userData != null}');

  //   // Check if categories have already been initialized
  //   final bool isInitialized = userData?['todoInitialized'] ?? false;
  //   print('🟢 Categories initialized: $isInitialized');

  //   if (!isInitialized) {
  //     print('🟢 Creating initial todo categories for user: $userId');

  //     final initialCategories = [];

  //     // Use a batch write for better performance
  //     final batch = _firestore.batch();

  //     for (var category in initialCategories) {
  //       final docRef = _firestore
  //           .collection('users')
  //           .doc(userId)
  //           .collection('todos')
  //           .doc(); // Auto-generate document ID

  //       batch.set(docRef, {
  //         'toDoName': category['toDoName'],
  //         'toDoItems': category['toDoItems'],
  //         'createdAt': FieldValue.serverTimestamp(),
  //         'userId': userId,
  //         'collaborators': [], // Initialize empty collaborators list
  //         'comments': [], // Initialize empty comments list
  //       });
  //     }

  //     // Set the initialization flag to true
  //     batch.update(_firestore.collection('users').doc(userId),
  //         {'todoInitialized': true});

  //     // Commit all operations at once
  //     await batch.commit();

  //     print(
  //         "Initial todo categories created successfully and marked as initialized");
  //   } else {
  //     print(
  //         "User's todo categories were already initialized, skipping creation");
  //   }
  // }

  // Create a new todo list
  Future<ToDoModel> createTodo(
      String toDoName, List<String> toDoItems, String? categoryId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // If categoryId is provided, verify category exists and user has access
    if (categoryId != null && categoryId.isNotEmpty) {
      final category = await _categoryService.getCategory(categoryId);
      if (category == null) {
        throw Exception('Category not found');
      }
    }

    final docRef =
        _firestore.collection('users').doc(userId).collection('todos').doc();

    // Convert string items to maps with isChecked: false
    final List<Map<String, dynamic>> itemsWithCheckedState = toDoItems
        .map((item) => {
              'name': item,
              'isChecked': false,
            })
        .toList();

    final todo = ToDoModel(
      id: docRef.id,
      toDoName: toDoName,
      toDoItems: itemsWithCheckedState,
      userId: userId!,
      categoryId: categoryId,
      collaborators: [],
      comments: [],
    );

    await docRef.set(todo.toMap());
    return todo;
  }

  // Get all todo lists accessible to the current user
  Future<List<ToDoModel>> getTodos() async {
    if (userId == null) {
      print('🔴 Cannot get todos: User not logged in');
      throw Exception('User not logged in');
    }

    try {
      print('🟢 Fetching todos for user: $userId');

      // Get todos where user is the owner
      final ownedSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .get();

      print('🟢 Found ${ownedSnapshot.docs.length} owned todos');

      final ownedTodos = ownedSnapshot.docs
          .map((doc) => ToDoModel.fromFirestore(doc))
          .toList();

      // Get pending invitations for each todo
      for (var todo in ownedTodos) {
        final pendingInvitations = await _firestore
            .collection('invitations')
            .where('todoId', isEqualTo: todo.id)
            .where('status', isEqualTo: 'pending')
            .get();

        // Add pending invitees to collaborators count
        final pendingInvitees = pendingInvitations.docs
            .map((doc) => doc.data()['inviteeId'] as String)
            .where((inviteeId) => !todo.collaborators.contains(inviteeId))
            .toList();

        todo.collaborators.addAll(pendingInvitees);
      }

      // Get collaborated todos from user's own collection
      final collaboratedTodos = ownedTodos
          .where((todo) => todo.collaborators.contains(userId))
          .toList();

      print('🟢 Found ${collaboratedTodos.length} collaborated todos');

      // Get accepted collaborations
      final collaborationsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('collaborations')
          .where('status', isEqualTo: 'accepted')
          .get();

      print(
          '🟢 Found ${collaborationsSnapshot.docs.length} accepted collaborations');

      // Get todo IDs from accepted collaborations
      final acceptedTodoIds = collaborationsSnapshot.docs
          .map((doc) => doc.data()['todoId'] as String)
          .toSet();

      // Add todos from accepted collaborations
      for (final todo in ownedTodos) {
        if (acceptedTodoIds.contains(todo.id) &&
            !collaboratedTodos.contains(todo)) {
          collaboratedTodos.add(todo);
        }
      }

      print('🟢 Total collaborated todos: ${collaboratedTodos.length}');

      // Return all todos
      return ownedTodos;
    } catch (e) {
      print('🔴 Error loading todos: $e');
      throw Exception('Failed to load todos: $e');
    }
  }

  // Get todos for a specific category
  Future<List<ToDoModel>> getTodosByCategory(String? categoryId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }
    if (categoryId == null || categoryId.isEmpty) {
      // If no categoryId, return empty list (or all todos if you prefer)
      return [];
    }
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs.map((doc) => ToDoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error loading todos for category: $e');
      throw Exception('Failed to load todos for category: $e');
    }
  }

  // Update a todo list
  Future<void> updateTodo(ToDoModel todo) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Check if user has access to this todo
    final hasAccess = await _collaborationService.hasAccess(todo.id!);
    if (!hasAccess && todo.userId != userId) {
      throw Exception('User does not have access to this todo');
    }

    await _firestore
        .collection('users')
        .doc(todo.userId)
        .collection('todos')
        .doc(todo.id)
        .update(todo.toMap());
  }

  // Delete a todo list
  Future<void> deleteTodo(String todoId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Check if user is the owner
    final todoDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .get();

    if (!todoDoc.exists) {
      throw Exception('Todo not found');
    }

    final todo = ToDoModel.fromFirestore(todoDoc);
    if (todo.userId != userId) {
      throw Exception('Only the owner can delete the todo');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .delete();
  }

  // Add a comment to a todo list
  Future<void> addComment(String todoId, String comment) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Get current user's name
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Anonymous';

    // First try to find the todo in user's own todos
    var todoDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .get();

    // If not found in user's todos, search in collaborated todos
    if (!todoDoc.exists) {
      final collaboratedSnapshot = await _firestore
          .collectionGroup('todos')
          .where('collaborators', arrayContains: userId)
          .get();

      final collaboratedDoc = collaboratedSnapshot.docs
          .where((doc) => doc.id == todoId)
          .firstOrNull;

      if (collaboratedDoc != null) {
        todoDoc = collaboratedDoc;
      } else {
        throw Exception('Todo not found');
      }
    }

    final todo = ToDoModel.fromFirestore(todoDoc);
    final updatedTodo = todo.addComment(userId!, userName, comment);

    // Update the todo in the owner's collection
    await _firestore
        .collection('users')
        .doc(todo.userId)
        .collection('todos')
        .doc(todoId)
        .update(updatedTodo.toMap());
  }

  // Add a collaborator to a todo list
  Future<void> addCollaborator(String todoId, String collaboratorId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Check if user is the owner
    final todoDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .get();

    if (!todoDoc.exists) {
      throw Exception('Todo not found');
    }

    final todo = ToDoModel.fromFirestore(todoDoc);
    if (todo.userId != userId) {
      throw Exception('Only the owner can add collaborators');
    }

    final updatedTodo = todo.addCollaborator(collaboratorId);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .update(updatedTodo.toMap());
  }

  // Remove a collaborator from a todo list
  Future<void> removeCollaborator(String todoId, String collaboratorId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Check if user is the owner
    final todoDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .get();

    if (!todoDoc.exists) {
      throw Exception('Todo not found');
    }

    final todo = ToDoModel.fromFirestore(todoDoc);
    if (todo.userId != userId) {
      throw Exception('Only the owner can remove collaborators');
    }

    final updatedTodo = todo.removeCollaborator(collaboratorId);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .update(updatedTodo.toMap());
  }

  // Get a todo by its ID
  Future<ToDoModel?> getTodoById(String todoId) async {
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(todoId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ToDoModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting todo by ID: $e');
      throw Exception('Failed to get todo: $e');
    }
  }
}

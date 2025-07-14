import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/services/email_service.dart';
import 'package:four_secrets_wedding_app/services/push_notification_service.dart';

import '../model/to_do_model.dart';
import 'category_service.dart';
import 'collaboration_service.dart';

class TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollaborationService _collaborationService = CollaborationService();
  final CategoryService _categoryService = CategoryService();
  final PushNotificationService _notificationService =
      PushNotificationService();
  String? get userId => _auth.currentUser?.uid;
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

  //     final initialCategories = [
  //       {
  //         'toDoName': 'Dokumente & Organisatorisches',
  //         'toDoItems': [
  //           'Personalausweis oder Reisepass',
  //           'Ablaufplan',
  //           'Kontaktdaten wichtiger Dienstleister',
  //           'Trinkgeld (in Umschlägen vorbereitet)',
  //         ],
  //       },
  //       {
  //         'toDoName': 'Braut',
  //         'toDoItems': [
  //           'Notfallset: Pflaster, Sicherheitsnadeln, Nähset, Kopfschmerztabletten',
  //           'Make-up zum Nachbessern (Puder, Lippenstift, Taschentücher)',
  //           'Deo & Parfum',
  //           'Ersatzstrumpfhose / -schuhe',
  //           'Mini-Haarspray',
  //         ],
  //       },
  //       {
  //         'toDoName': 'Bräutigam',
  //         'toDoItems': [
  //           'Ersatzhemd (bei warmem Wetter)',
  //           'Schuhputztuch',
  //           'Deo',
  //           'Taschentücher',
  //         ],
  //       },
  //       {
  //         'toDoName': 'Technik',
  //         'toDoItems': [
  //           'Geladene Handys + Powerbank',
  //           'Eheringe',
  //           'Traurede',
  //         ],
  //       },
  //       {
  //         'toDoName': 'Snacks & Getränke',
  //         'toDoItems': [
  //           'Kleine Snacks (Nüsse, Riegel)',
  //           'Wasserflaschen',
  //           'Strohhalm (für die Braut mit Make-up)',
  //         ],
  //       },
  //       {
  //         'toDoName': 'Sonstiges',
  //         'toDoItems': [
  //           'Kleine Decke (falls Fotos draußen stattfinden)',
  //           'Regenschirm',
  //         ],
  //       }
  //     ];

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

  // // Create a new todo list
  // Future<ToDoModel> createTodo(
  //     {String? toDoName,
  //     List<String>? toDoItems,
  //     String? categoryId,
  //     List<Map<String, dynamic>>? categories}) async {
  //   // Defensive: Ensure userId is valid
  //   if (userId == null || userId!.isEmpty) {
  //     print('ERROR: userId is null or empty in createTodo');
  //     throw Exception('User not logged in');
  //   }
  //   // Defensive: Ensure we never use an empty string in Firestore paths
  //   if (_firestore.collection('users').doc(userId).id.isEmpty) {
  //     print('ERROR: Firestore user doc id is empty!');
  //     throw Exception('Firestore user doc id is empty!');
  //   }
  //   // Defensive: Ensure categories or toDoItems are provided
  //   if ((categories == null || categories.isEmpty) &&
  //       (toDoItems == null || toDoItems.isEmpty)) {
  //     print('ERROR: No categories or toDoItems provided to createTodo');
  //     throw Exception('No todo items or categories provided');
  //   }
  //   // Defensive: If categoryId is provided, ensure it is not empty and valid
  //   if (categoryId != null) {
  //     if (categoryId.isEmpty) {
  //       print('ERROR: categoryId is an empty string!');
  //       throw Exception('Category ID must not be an empty string');
  //     }
  //     final category = await _categoryService.getCategory(categoryId);
  //     if (category == null) {
  //       throw Exception('Category not found');
  //     }
  //   }
  //   // Defensive: Ensure no empty category names in categories
  //   if (categories != null &&
  //       categories.any((cat) => (cat['categoryName'] == null ||
  //           cat['categoryName'].toString().trim().isEmpty))) {
  //     print('ERROR: One or more category names are empty!');
  //     throw Exception('One or more category names are empty!');
  //   }
  //   final docRef =
  //       _firestore.collection('users').doc(userId).collection('todos').doc();
  //   // Convert string items to maps with isChecked: false (for old format)
  //   final List<Map<String, dynamic>> itemsWithCheckedState = (toDoItems ?? [])
  //       .map((item) => {
  //             'name': item,
  //             'isChecked': false,
  //           })
  //       .toList();
  //   final todo = ToDoModel(
  //     id: docRef.id,
  //     toDoName: toDoName ?? '',
  //     toDoItems: itemsWithCheckedState,
  //     userId: userId!,
  //     categoryId: categoryId,
  //     collaborators: [],
  //     comments: [],
  //     categories: categories,
  //   );
  //   try {
  //     print('🔥🔥🔥 About to create Firestore docRef');
  //     print('🔥🔥🔥 Firestore docRef created: \n${docRef.path}');
  //     print('🔥🔥🔥 Data to be sent to Firestore: \n${todo.toMap()}');
  //     await docRef.set(todo.toMap());
  //     return todo;
  //   } catch (e, stack) {
  //     print('🔥🔥🔥 Exception creating Firestore docRef or saving: $e');
  //     print(stack);
  //     rethrow;
  //   }
  // }

  Future<bool> checkForDuplicateCategory(String categoryName) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .where('categoryName', isEqualTo: categoryName)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('🔴🔴🔴 Error checking for duplicate category: $e');
      return false;
    }
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

      // Get todos where user is a collaborator or revokedFor
      final sharedSnapshot = await _firestore
          .collectionGroup('todos')
          .where('collaborators', arrayContains: userId)
          .get();
      final revokedSnapshot = await _firestore
          .collectionGroup('todos')
          .where('revokedFor', arrayContains: userId)
          .get();

      final sharedTodos = sharedSnapshot.docs
          .map((doc) => ToDoModel.fromFirestore(doc))
          .where((todo) => todo.userId != userId)
          .toList();
      final revokedTodos = revokedSnapshot.docs
          .map((doc) => ToDoModel.fromFirestore(doc))
          .where((todo) => todo.userId != userId)
          .toList();

      // Merge and deduplicate
      final allTodos = <String, ToDoModel>{};
      for (final todo in [...ownedTodos, ...sharedTodos, ...revokedTodos]) {
        allTodos[todo.id!] = todo;
      }
      return allTodos.values.toList();
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
    final hasAccess = await _collaborationService.hasAccess(todo.id!);
    final currentUser = _auth.currentUser;
    // Allow if current user is owner by UID or by email, or collaborator (by email, not revoked)
    final isCollaborator = todo.collaborators.contains(currentUser?.email) &&
        !(todo.revokedFor.contains(currentUser?.email));
    if (!hasAccess &&
        todo.userId != userId &&
        todo.ownerEmail != currentUser?.email &&
        !isCollaborator) {
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
  Future<void> addCollaborator(String todoId, String collaboratorEmail,
      {bool addToGlobal = false}) async {
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

    final updatedTodo = todo.addCollaborator(collaboratorEmail);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .update(updatedTodo.toMap());
    // Only add to globalCollaborators if requested
    if (addToGlobal) {
      await _firestore.collection('users').doc(userId).update({
        'globalCollaborators': FieldValue.arrayUnion([collaboratorEmail]),
      });
    }
  }

  // Remove a collaborator from a todo list
  // Future<void> removeCollaborator(String todoId, String collaboratorId) async {
  //   if (userId == null) {
  //     throw Exception('User not logged in');
  //   }

  //   // Check if user is the owner
  //   final todoDoc = await _firestore
  //       .collection('users')
  //       .doc(userId)
  //       .collection('todos')
  //       .doc(todoId)
  //       .get();

  //   if (!todoDoc.exists) {
  //     throw Exception('Todo not found');
  //   }

  //   final todo = ToDoModel.fromFirestore(todoDoc);
  //   if (todo.userId != userId) {
  //     throw Exception('Only the owner can remove collaborators');
  //   }

  //   final updatedTodo = todo.removeCollaborator(collaboratorId);
  //   await _firestore
  //       .collection('users')
  //       .doc(userId)
  //       .collection('todos')
  //       .doc(todoId)
  //       .update(updatedTodo.toMap());
  // }
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

    // Remove collaborator and add to revokedFor
    final updatedCollaborators = List<String>.from(todo.collaborators)
      ..remove(collaboratorId);
    final updatedRevokedFor = List<String>.from(todo.revokedFor)
      ..add(collaboratorId); // Add to revokedFor if not already present
    final updatedTodo = todo.copyWith(
      collaborators: updatedCollaborators,
      revokedFor: updatedRevokedFor,
      isShared: updatedCollaborators
          .isNotEmpty, // Update isShared based on remaining collaborators
    );

    // Update Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .update(updatedTodo.toMap());

    // Remove from globalCollaborators
    await _firestore.collection('users').doc(userId).update({
      'globalCollaborators': FieldValue.arrayRemove([collaboratorId]),
    });

    // Send push notification to the collaborator
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: collaboratorId)
        .limit(1)
        .get();
    if (userQuery.docs.isNotEmpty) {
      final collaboratorUid = userQuery.docs.first.id;
      await _notificationService.sendNotification(
        userId: collaboratorUid,
        title: 'Zugriff entzogen',
        body: 'Der Zugriff auf die Liste "${todo.toDoName}" wurde entzogen',
        data: {'type': 'access_revoked'},
      );
    }

    // Send revocation email
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final inviterName = userDoc.data()?['name'] ?? todo.ownerEmail ?? 'Unknown';
    final emailService = EmailService();
    await emailService.sendRevokeAccessEmail(
      email: collaboratorId,
      inviterName: inviterName,
    );
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

  Future<void> createTodo({
    required List<Map<String, dynamic>> categories,
    String? toDoName,
    List<Map<String, dynamic>>? toDoItems,
    String? reminder,
    List<String>? collaborators,
    List<Map<String, dynamic>>? comments,
    String? categoryId,
    bool isShared = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    // Fetch global collaborators for this user
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final globalCollaborators =
        List<String>.from(userDoc.data()?['globalCollaborators'] ?? []);
    final shouldShare = isShared || globalCollaborators.isNotEmpty;
    final todoData = {
      'userId': user.uid,
      'ownerId': user.uid,
      'ownerEmail': user.email, // <-- Ensure ownerEmail is always set
      'categories': categories,
      if (toDoName != null) 'toDoName': toDoName,
      if (toDoItems != null) 'toDoItems': toDoItems,
      if (reminder != null) 'reminder': reminder,
      'collaborators': globalCollaborators.isNotEmpty
          ? globalCollaborators
          : (collaborators ?? []),
      'comments': comments ?? [],
      if (categoryId != null) 'categoryId': categoryId,
      'isShared': shouldShare,
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .add(todoData);
  }

  // Remove all collaborators from a todo list (revoke access for all)
  // Future<void> removeAllCollaborators(String todoId) async {
  //   if (userId == null) {
  //     throw Exception('User not logged in');
  //   }
  //   // Check if user is the owner
  //   final todoDoc = await _firestore
  //       .collection('users')
  //       .doc(userId)
  //       .collection('todos')
  //       .doc(todoId)
  //       .get();
  //   if (!todoDoc.exists) {
  //     throw Exception('Todo not found');
  //   }
  //   final todo = ToDoModel.fromFirestore(todoDoc);
  //   if (todo.userId != userId) {
  //     throw Exception('Only the owner can revoke all collaborators');
  //   }
  //   // Add all current collaborators to revokedFor
  //   final prevCollaborators = List<String>.from(todo.collaborators)
  //     ..removeWhere((email) => email == todo.ownerEmail);
  //   final userRef = _firestore.collection('users').doc(userId);
  //   // Remove all collaborators from globalCollaborators as well
  //   await userRef.update({
  //     'globalCollaborators': FieldValue.arrayRemove(prevCollaborators),
  //   });
  //   final updatedTodo = todo.copyWith(
  //     collaborators: [],
  //     isShared: false,
  //     revokedFor: prevCollaborators,
  //   );
  //   // Send notification to all collaborators (not the owner)
  //   for (final collaboratorEmail in prevCollaborators) {
  //     // Find userId by email
  //     final userQuery = await _firestore
  //         .collection('users')
  //         .where('email', isEqualTo: collaboratorEmail)
  //         .limit(1)
  //         .get();
  //     if (userQuery.docs.isNotEmpty) {
  //       final collaboratorId = userQuery.docs.first.id;
  //       await _notificationService.sendNotification(
  //         userId: collaboratorId,
  //         title: 'Zugriff entzogen',
  //         body: 'Der Zugriff auf die Liste "${todo.toDoName}" wurde entzogen',
  //         data: {'type': 'access_revoked'},
  //       );
  //     }
  //   }
  //   await _firestore
  //       .collection('users')
  //       .doc(userId)
  //       .collection('todos')
  //       .doc(todoId)
  //       .update(updatedTodo.toMap());
  // }
  Future<void> removeAllCollaborators(String todoId) async {
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
      throw Exception('Only the owner can revoke all collaborators');
    }
    // Add all current collaborators to revokedFor
    final prevCollaborators = List<String>.from(todo.collaborators)
      ..removeWhere((email) => email == todo.ownerEmail);
    final userRef = _firestore.collection('users').doc(userId);
    // Remove all collaborators from globalCollaborators as well
    await userRef.update({
      'globalCollaborators': FieldValue.arrayRemove(prevCollaborators),
    });
    final updatedTodo = todo.copyWith(
      collaborators: [],
      isShared: false,
      revokedFor: prevCollaborators,
    );
    // Send notification to all collaborators (not the owner)
    for (final collaboratorEmail in prevCollaborators) {
      // Find userId by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: collaboratorEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final collaboratorId = userQuery.docs.first.id;
        await _notificationService.sendNotification(
          userId: collaboratorId,
          title: 'Zugriff entzogen',
          body: 'Der Zugriff auf die Liste "${todo.toDoName}" wurde entzogen',
          data: {'type': 'access_revoked'},
        );
      }
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .update(updatedTodo.toMap());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/model/to_do_data_base.dart';
// import 'package:four_secrets_wedding_app/models/checklist_item_model.dart';

class ToDoDataBase {
  List<ChecklistItemModel> toDoList = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Create initial data for first-time users
  Future<void> createInitialDataToDo() async {
    if (userId == null) {
      print("Cannot create initial data: User not logged in");
      return;
    }
    
    // First check if user document exists
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    // If user document doesn't exist, create it with an initialization flag
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(userId).set({
        'checklistInitialized': false,
      });
    }
    
    // Get the user document (it definitely exists now)
    final userData = (await _firestore.collection('users').doc(userId).get()).data();
    
    // Check if checklist has already been initialized
    final bool isInitialized = userData?['checklistInitialized'] ?? false;
    
    if (!isInitialized) {
      print("Creating initial checklist for user: $userId");
      
      final initialTasks = [
        ["Übernachtung Gäste", false],
        ["Flitterwochen organisieren", false],
        ["Fotograf organisieren", false],
        ["Location aussuchen/buchen", false],
        ["Trauzeugen bestimmen", false],
        ["Eheringe aussuchen", false],
        ["Brautkleid aussuchen/anprobieren", false],
        ["Hochzeitstorte bestellen", false],
        ["Geschenke für die Gäste?", false],
        ["Trauzeugen Outfit bestimmen", false],
        ["Eventprogramm planen", false],
        ["Sitzplan erstellen", false],
        ["Deko organisieren", false],
        ["Floristen aussuchen", false],
        ["Hochzeitsrede schreiben", false],
        ["Wedding Designer buchen", false],
        ["Personal Training organisieren", false],
        ["Tanzkurs besuchen", false],
        ["Jungg. Abschied planen/feiern", false],
        ["Ringkissen aussuchen", false],
        ["DJ/Band organisieren", false]
      ];
      
      // Use a batch write for better performance
      final batch = _firestore.batch();
      
      for (var item in initialTasks) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('checklist')
            .doc(); // Auto-generate document ID
            
        batch.set(docRef, {
          'taskName': item[0],
          'isCompleted': item[1],
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
        });
      }
      
      // Set the initialization flag to true
      batch.update(_firestore.collection('users').doc(userId), {
        'checklistInitialized': true
      });
      
      // Commit all operations at once
      await batch.commit();
      
      print("Initial checklist created successfully and marked as initialized");
    } else {
      print("User's checklist was already initialized, skipping creation");
    }
  }

  // Load data from Firebase
  Future<void> loadDataToDo() async {
    if (userId == null) {
      print("Cannot load data: User not logged in");
      return;
    }
    
    // Clear existing data to prevent duplication
    toDoList.clear();
    
    try {
      // First check if we need to initialize the checklist
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists || !(userDoc.data()?['checklistInitialized'] ?? false)) {
        print("Checklist not initialized yet, creating initial data");
        await createInitialDataToDo();
      } else {
        print("Checklist already initialized, loading data");
      }
      
      // Now load all checklist items
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checklist')
          .orderBy('createdAt', descending: true) // Latest items on top
          .get();
    

      if (snapshot.docs.isEmpty) {
        print("Warning: No checklist items found even though collection should be initialized");
      }
      
      toDoList = snapshot.docs
          .map((doc) => ChecklistItemModel.fromFirestore(doc))
          .toList();
      
      print("Loaded ${toDoList.length} checklist items for user: $userId");
    } catch (e) {
      print('Error loading checklist: $e');
    }
  }

  // Add a new task to Firebase
  Future<void> addTask(String taskName) async {
    if (userId == null) {
      print("Cannot add task: User not logged in");
      return;
    }
    
    try {
      final now = DateTime.now();
      final newTask = ChecklistItemModel(
        id: '', // Will be set by Firestore
        taskName: taskName,
        isCompleted: false,
        createdAt: now,
        userId: userId!,
      );
      
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checklist')
          .add(newTask.toMap());
      
      // Add to local list with the generated ID
      final taskWithId = newTask.copyWith(id: docRef.id);
      toDoList.insert(0, taskWithId);
      
      print("Added task: $taskName");
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  // Update task status in Firebase
  Future<void> updateTaskStatus(int index, bool isCompleted) async {
    if (userId == null || index >= toDoList.length) {
      print("Cannot update task: User not logged in or invalid index");
      return;
    }
    
    try {
      final task = toDoList[index];
      final updatedTask = task.copyWith(isCompleted: isCompleted);
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('checklist')
          .doc(task.id)
          .update({
        'isCompleted': isCompleted,
      });
      
      // Update local list
      toDoList[index] = updatedTask;
      
      print("Updated task status: ${task.taskName} to $isCompleted");
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  // Delete task from Firebase
  Future<void> deleteTask(int index) async {
    if (userId == null || index >= toDoList.length) {
      print("Cannot delete task: User not logged in or invalid index");
      return;
    }
    
    try {
      final task = toDoList[index];
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('checklist')
          .doc(task.id)
          .delete();
      
      // Remove from local list
      toDoList.removeAt(index);
      
      print("Deleted task: ${task.taskName}");
    } catch (e) {
      print('Error deleting task: $e');
    }
  }
}

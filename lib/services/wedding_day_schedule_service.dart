import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';

class WeddingDayScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<WeddingDayScheduleModel> weddingDayScheduleList = [];

  String? get userId => _auth.currentUser?.uid;
Future<String?> addScheduleItem({
  required String title,
  required String description,
  required DateTime time,
  required bool reminderEnabled,
  required DateTime reminderTime,
  required String responsiblePerson,
  required String notes,
}) async {
  if (userId == null) {
    throw StateError('User must be logged in to add a schedule item.');
  }

  final currentCount = weddingDayScheduleList.length;

  final newScheduleItem = WeddingDayScheduleModel(
    id: null, // Firestore will generate
    title: title,
    description: description,
    responsiblePerson: responsiblePerson,
    notes: notes,
    time: time,
    reminderEnabled: reminderEnabled,
    reminderTime: reminderTime,
    userId: userId!,
    order: currentCount,
  );

  try {
    // Add the item to Firestore and wait for the DocumentReference
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weddingDaySchedule')
        .add(newScheduleItem.toMap());
    
    final id = docRef.id; // Get the generated ID
    print("Added schedule item: $title with ID: $id");
    
    // Optionally, schedule the alarm if reminder is enabled
    if (reminderEnabled) {
      await NotificationService.scheduleAlarmNotification(
        id: id.hashCode, // Use a unique ID, e.g., hash of the document ID
        dateTime: reminderTime,
        title: "Wedding Reminder: $title",
        body: description,
        payload: id,
      );
    }

    return id; // Return the non-null ID
  } catch (e) {
    print('Error adding schedule item: $e');
    return null; // Return null on error instead of an empty string
  }
}



Future<void> loadData() async {
  if (userId == null) {
    print("Cannot load data: User not logged in");
    return;
  }
  weddingDayScheduleList.clear();
  try {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weddingDaySchedule')
        .orderBy('order', descending: false)
        .get();

    weddingDayScheduleList = snapshot.docs
        .map((doc) {
          print(doc.data());
          return WeddingDayScheduleModel.fromMap(doc.data())
              .copyWith(id: doc.id);
        })
        .toList();

    print("Loaded ${weddingDayScheduleList.length} schedule items");

    // Schedule alarms for items with reminders enabled
    for (var item in weddingDayScheduleList) {
      if (item.reminderEnabled) {
        await NotificationService.scheduleAlarmNotification(
          id: item.id.hashCode, // Unique ID based on document ID
          dateTime: item.reminderTime,
          title: "Wedding Reminder: ${item.title}",
          body: item.description,
          payload: item.id,
        );
      }
    }
  } catch (e) {
    print('Error loading schedule: $e');
  }
}
  // Delete schedule item from Firebase
  Future<void> deleteScheduleItem(String id) async {
    if (userId == null) return;

    try {
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('weddingDaySchedule')
        .doc(id)
        .delete();

      // Then reload to keep list in sync
      // await loadData();
      print("Deleted and reloaded schedule items: $id");
    } catch (e) {
      print('Error deleting schedule item: $e');
    }
  }


  Future<void> updateOrder(WeddingDayScheduleModel item) async {
    if (userId == null) {
      throw StateError('User must be logged in to update order.');
    }

    try {
     
        await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingDaySchedule')
          .doc(item.id)
          .update({
            'title': item.title,
            'description': item.description,
            'time': Timestamp.fromDate(item.time),
            'reminderEnabled': item.reminderEnabled,
            'reminderTime': Timestamp.fromDate(item.reminderTime),
            'userId': item.userId,
            'responsiblePerson': item.responsiblePerson,
            'notes': item.notes,
            'order': item.order});
      

      // Then reload to keep list in sync
      // await loadData();
      print("Updated and reloaded schedule items: ${item.id}, ${item.title}");
    } catch (e) {
      print('Error updating schedule item: $e');
    }
  }

/// Rewrites every item's `order` field in Firestore to match its
/// index in [reordered], then replaces your local list.
Future<void> updateOrderItemsList(List<WeddingDayScheduleModel> reordered) async {
  if (userId == null) {
    throw StateError('User must be logged in to reorder items.');
  }

  final batch = _firestore.batch();
  final colRef = _firestore
      .collection('users')
      .doc(userId)
      .collection('weddingDaySchedule');

  for (var i = 0; i < reordered.length; i++) {
    final item = reordered[i];
    if (item.order != i) {
      final docRef = colRef.doc(item.id);
      batch.update(docRef, {'order': i});
      reordered[i] = item.copyWith(order: i);
    }
  }

  await batch.commit();
  // Update the in-memory list in one go
  weddingDayScheduleList = List.of(reordered);
  print('Reordered ${reordered.length} items in Firestore.');
}

}

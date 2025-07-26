import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';

class WeddingDayScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<WeddingDayScheduleModel> weddingDayScheduleList = [];

  String? get userId => _auth.currentUser?.uid;

  /// Checks if items have been manually reordered by looking for
  /// order values that don't match the timestamp-based order
  bool _hasManualReordering(List<WeddingDayScheduleModel> items) {
    if (items.length <= 1) return false;

    // Check for problematic order values (all items have the same order)
    final uniqueOrders = items.map((item) => item.order).toSet();
    if (uniqueOrders.length == 1 && uniqueOrders.first == 0) {
      print("Problematic order values detected: all items have order 0");
      // Auto-fix: Reset all items to timestamp-based ordering
      _autoFixOrderValues();
      return false; // Return false to use timestamp sorting after fix
    }

    // Check if items are using manual ordering (small sequential numbers)
    final hasSmallOrders = items.any((item) => item.order < 1000);
    if (hasSmallOrders) {
      // Verify if this is valid manual ordering (sequential numbers)
      final sortedByOrder = List<WeddingDayScheduleModel>.from(items)
        ..sort((a, b) => a.order.compareTo(b.order));

      // Check if orders are sequential or at least unique
      final orders = sortedByOrder.map((item) => item.order).toList();
      final hasUniqueOrders = orders.toSet().length == orders.length;

      if (hasUniqueOrders) {
        print("Valid manual reordering detected (sequential order values)");
        return true;
      }
    }

    // Additional check: if items are not in chronological order by their order field
    final sortedByOrder = List<WeddingDayScheduleModel>.from(items)
      ..sort((a, b) => a.order.compareTo(b.order));

    for (int i = 0; i < sortedByOrder.length - 1; i++) {
      final current = sortedByOrder[i];
      final next = sortedByOrder[i + 1];

      // If a later item in order has an earlier time, manual reordering occurred
      if (current.time.isAfter(next.time)) {
        print(
            "Manual reordering detected: chronological order doesn't match order field");
        return true;
      }
    }

    return false;
  }

  /// Auto-fixes order values by setting them to timestamps
  void _autoFixOrderValues() {
    print("Auto-fixing order values to use timestamps...");
    // This will be handled asynchronously to avoid blocking the UI
    Future.microtask(() async {
      try {
        await resetToTimeBasedOrder();
        print("Order values auto-fixed successfully");
      } catch (e) {
        print("Failed to auto-fix order values: $e");
      }
    });
  }

  /// Calculates the appropriate order value for a new item based on current ordering system
  Future<int> _calculateNewItemOrder(DateTime newItemTime) async {
    // If no items exist, use timestamp
    if (weddingDayScheduleList.isEmpty) {
      return newItemTime.millisecondsSinceEpoch;
    }

    // Check if current items are using manual ordering
    final hasManualOrder = _hasManualReordering(weddingDayScheduleList);

    if (hasManualOrder) {
      // Manual ordering is active - find the correct position based on time
      print(
          "Manual ordering detected - inserting new item in chronological position");

      // Sort existing items by their current order
      final sortedByOrder =
          List<WeddingDayScheduleModel>.from(weddingDayScheduleList)
            ..sort((a, b) => a.order.compareTo(b.order));

      // Find where the new item should be inserted based on time
      int insertPosition = 0;
      for (int i = 0; i < sortedByOrder.length; i++) {
        if (newItemTime.isBefore(sortedByOrder[i].time)) {
          insertPosition = i;
          break;
        }
        insertPosition = i + 1;
      }

      print("New item should be inserted at position $insertPosition");

      // Update order values for all items to make room for the new item
      await _makeRoomForNewItem(insertPosition);

      return insertPosition;
    } else {
      // Timestamp-based ordering - use timestamp
      print("Timestamp-based ordering - using timestamp as order");
      return newItemTime.millisecondsSinceEpoch;
    }
  }

  /// Makes room for a new item at the specified position by updating order values
  Future<void> _makeRoomForNewItem(int insertPosition) async {
    if (userId == null) return;

    final batch = _firestore.batch();
    final colRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('weddingDaySchedule');

    // Sort existing items by their current order
    final sortedByOrder =
        List<WeddingDayScheduleModel>.from(weddingDayScheduleList)
          ..sort((a, b) => a.order.compareTo(b.order));

    // Update order values for items at and after the insert position
    for (int i = insertPosition; i < sortedByOrder.length; i++) {
      final item = sortedByOrder[i];
      final newOrder = i + 1; // Shift by 1 to make room

      final docRef = colRef.doc(item.id);
      batch.update(docRef, {'order': newOrder});

      // Update local list
      final index =
          weddingDayScheduleList.indexWhere((element) => element.id == item.id);
      if (index != -1) {
        weddingDayScheduleList[index] = item.copyWith(order: newOrder);
      }
    }

    await batch.commit();
    print("Made room for new item at position $insertPosition");
  }

  Future<String?> addScheduleItem(
      {required String title,
      // required String description,
      required DateTime time,
      required bool reminderEnabled,
      DateTime? reminderTime, // Make nullable
      required String responsiblePerson,
      required String notes,
      required String address,
      required double lat,
      required double long}) async {
    if (userId == null) {
      throw StateError('User must be logged in to add a schedule item.');
    }

    // Determine the appropriate order value based on current ordering system
    final temporaryOrder = await _calculateNewItemOrder(time);

    final newScheduleItem = WeddingDayScheduleModel(
        id: null, // Firestore will generate
        title: title,
        // description: description,
        responsiblePerson: responsiblePerson,
        notes: notes,
        time: time,
        reminderEnabled: reminderEnabled,
        reminderTime: reminderTime, // Can be null
        userId: userId!,
        order: temporaryOrder,
        address: address,
        lat: lat,
        long: long);

    try {
      // Add the item to Firestore and wait for the DocumentReference
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingDaySchedule')
          .add(newScheduleItem.toMap());

      final id = docRef.id; // Get the generated ID
      print("Added schedule item: $title with ID: $id");

      // Optionally, schedule the alarm if reminder is enabled AND reminderTime is not null
      if (reminderEnabled && reminderTime != null) {
        try {
          await NotificationService.scheduleAlarmNotification(
            id: id.hashCode, // Use a unique ID, e.g., hash of the document ID
            dateTime: reminderTime,
            title: "Hochzeits-Erinnerung: $title",
            body: notes,
            payload: id,
          );
          print("✅ Notification scheduled for: $title at $reminderTime");
        } catch (e) {
          print("❌ Failed to schedule notification for: $title - Error: $e");
        }
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
          .get(); // Remove orderBy to get all items first

      weddingDayScheduleList = snapshot.docs.map((doc) {
        return WeddingDayScheduleModel.fromMap(doc.data()).copyWith(id: doc.id);
      }).toList();

      print("Loaded ${weddingDayScheduleList.length} schedule items");

      // Check if items have been manually reordered
      final hasManualOrder = _hasManualReordering(weddingDayScheduleList);

      if (hasManualOrder) {
        // Use manual order (sort by order field)
        weddingDayScheduleList.sort((a, b) => a.order.compareTo(b.order));
        print("Using manual order (items have been reordered)");
      } else {
        // Sort by date/time in ascending order (default behavior)
        weddingDayScheduleList.sort((a, b) {
          final aDateTime = DateTime(
            a.time.year,
            a.time.month,
            a.time.day,
            a.time.hour,
            a.time.minute,
          );
          final bDateTime = DateTime(
            b.time.year,
            b.time.month,
            b.time.day,
            b.time.hour,
            b.time.minute,
          );
          return aDateTime.compareTo(bDateTime); // Ascending order
        });
        print("Applied automatic date/time ascending sort");
      }

      // Schedule alarms for items with reminders enabled AND reminderTime is not null
      int scheduledCount = 0;
      int skippedCount = 0;
      for (var item in weddingDayScheduleList) {
        if (item.reminderEnabled && item.reminderTime != null) {
          try {
            await NotificationService.scheduleAlarmNotification(
              id: item.id.hashCode, // Unique ID based on document ID
              dateTime: item.reminderTime!,
              title: "Wedding Reminder: ${item.title}",
              body: item.notes,
              payload: item.id,
            );
            scheduledCount++;
          } catch (e) {
            print(
                "❌ Failed to schedule notification for: ${item.title} - Error: $e");
            skippedCount++;
          }
        }
      }
      print(
          "📅 Notification scheduling complete: $scheduledCount scheduled, $skippedCount skipped");
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
      Map<String, dynamic> updateData = {
        'title': item.title,
        // 'description': item.description,
        'time': Timestamp.fromDate(item.time),
        'reminderEnabled': item.reminderEnabled,
        'userId': item.userId,
        'responsiblePerson': item.responsiblePerson,
        'notes': item.notes,
        'order': item.order,
        'address': item.address,
        'lat': item.lat,
        'long': item.long
      };

      // Only add reminderTime if it's not null
      if (item.reminderTime != null) {
        updateData['reminderTime'] = Timestamp.fromDate(item.reminderTime!);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingDaySchedule')
          .doc(item.id)
          .update(updateData);

      // Then reload to keep list in sync
      // await loadData();
      print("Updated and reloaded schedule items: ${item.id}, ${item.title}");
    } catch (e) {
      print('Error updating schedule item: $e');
    }
  }

  /// Rewrites every item's `order` field in Firestore to match its
  /// index in [reordered], then replaces your local list.
  Future<void> updateOrderItemsList(
      List<WeddingDayScheduleModel> reordered) async {
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

  /// Resets all items to use timestamp-based ordering (removes manual ordering)
  Future<void> resetToTimeBasedOrder() async {
    if (userId == null) {
      throw StateError('User must be logged in to reset order.');
    }

    final batch = _firestore.batch();
    final colRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('weddingDaySchedule');

    // Update each item's order to its timestamp
    for (final item in weddingDayScheduleList) {
      final docRef = colRef.doc(item.id);
      final timestampOrder = item.time.millisecondsSinceEpoch;
      batch.update(docRef, {'order': timestampOrder});
    }

    await batch.commit();

    // Reload data to reflect changes
    await loadData();

    print(
        'Reset ${weddingDayScheduleList.length} items to timestamp-based order.');
  }
}

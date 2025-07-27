import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';

class WeddingDayScheduleService1 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<WeddingDayScheduleModel1> weddingDayScheduleList = [];

  String? get userId => _auth.currentUser?.uid;
  Future<String?> addScheduleItem({
    required String title,
    // required String description,
    required DateTime time,
    required bool reminderEnabled,
    DateTime? reminderTime, // Make nullable
    required String responsiblePerson,
    required String notes,
    required String address,
    required double lat,
    required double long,
    // New fields
    String dienstleistername = '',
    String kontaktperson = '',
    String telefonnummer = '',
    String email = '',
    String homepage = '',
    String instagram = '',
    String addressDetails = '',
    String angebotText = '',
    String angebotFileUrl = '',
    String angebotFileName = '',
    String zahlungsstatus = 'Unbezahlt',
    DateTime? probetermin,
  }) async {
    if (userId == null) {
      throw StateError('User must be logged in to add a schedule item.');
    }

    final currentCount = weddingDayScheduleList.length;

    final newScheduleItem = WeddingDayScheduleModel1(
        id: null, // Firestore will generate
        title: title,
        // description: description,
        responsiblePerson: responsiblePerson,
        notes: notes,
        time: time,
        reminderEnabled: reminderEnabled,
        reminderTime: reminderTime, // Can be null
        userId: userId!,
        order: currentCount,
        address: address,
        lat: lat,
        long: long,
        // New fields
        dienstleistername: dienstleistername,
        kontaktperson: kontaktperson,
        telefonnummer: telefonnummer,
        email: email,
        homepage: homepage,
        instagram: instagram,
        addressDetails: addressDetails,
        angebotText: angebotText,
        angebotFileUrl: angebotFileUrl,
        angebotFileName: angebotFileName,
        zahlungsstatus: zahlungsstatus,
        probetermin: probetermin);

    try {
      // Add the item to Firestore and wait for the DocumentReference
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingDaySchedule1')
          .add(newScheduleItem.toMap());

      final id = docRef.id; // Get the generated ID
      print("Added schedule item: $title with ID: $id");

      // Optionally, schedule the alarm if reminder is enabled AND reminderTime is not null
      if (reminderEnabled && reminderTime != null) {
        try {
          await NotificationService.scheduleAlarmNotification(
            id: id.hashCode, // Use a unique ID, e.g., hash of the document ID
            dateTime: reminderTime,
            title: "Hochzeits-Erinnerung1: $title",
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

  /// Checks if items have been manually reordered by looking for
  /// order values that don't match the timestamp-based order
  bool _hasManualReordering(List<WeddingDayScheduleModel1> items) {
    if (items.length <= 1) return false;

    // Check for problematic order values (all items have the same order)
    final uniqueOrders = items.map((item) => item.order).toSet();
    if (uniqueOrders.length == 1 && uniqueOrders.first == 0) {
      print("Problematic order values detected: all items have order 0");
      return false; // Use timestamp sorting
    }

    // Check if items are using manual ordering (small sequential numbers)
    final hasSmallOrders = items.any((item) => item.order < 1000);
    if (hasSmallOrders) {
      // Verify if this is valid manual ordering (sequential numbers)
      final sortedByOrder = List<WeddingDayScheduleModel1>.from(items)
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
    final sortedByOrder = List<WeddingDayScheduleModel1>.from(items)
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
          .collection('weddingDaySchedule1')
          .get(); // Remove orderBy to get all items first

      weddingDayScheduleList = snapshot.docs.map((doc) {
        print(doc.data());
        return WeddingDayScheduleModel1.fromMap(doc.data())
            .copyWith(id: doc.id);
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
              title: "Wedding Reminder1: ${item.title}",
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
      // Cancel notification for this item before deleting
      await NotificationService.cancel(id.hashCode);
      print("Cancelled notification for item: $id");

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingDaySchedule1')
          .doc(id)
          .delete();

      // Then reload to keep list in sync
      // await loadData();
      print("Deleted and reloaded schedule items: $id");
    } catch (e) {
      print('Error deleting schedule item: $e');
    }
  }

  Future<void> updateOrder(WeddingDayScheduleModel1 item) async {
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
        'long': item.long,
        // New fields
        'dienstleistername': item.dienstleistername,
        'kontaktperson': item.kontaktperson,
        'telefonnummer': item.telefonnummer,
        'email': item.email,
        'homepage': item.homepage,
        'instagram': item.instagram,
        'addressDetails': item.addressDetails,
        'angebotText': item.angebotText,
        'angebotFileUrl': item.angebotFileUrl,
        'angebotFileName': item.angebotFileName,
        'zahlungsstatus': item.zahlungsstatus,
      };

      // Only add reminderTime if it's not null
      if (item.reminderTime != null) {
        updateData['reminderTime'] = Timestamp.fromDate(item.reminderTime!);
      }

      // Only add probetermin if it's not null
      if (item.probetermin != null) {
        updateData['probetermin'] = Timestamp.fromDate(item.probetermin!);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weddingDaySchedule1')
          .doc(item.id)
          .update(updateData);

      // Cancel existing notification for this item
      await NotificationService.cancel(item.id.hashCode);

      // Schedule new notification if reminder is enabled and reminderTime is not null
      if (item.reminderEnabled && item.reminderTime != null) {
        await NotificationService.scheduleAlarmNotification(
          id: item.id.hashCode,
          dateTime: item.reminderTime!,
          title: "Hochzeits-Erinnerung1: ${item.title}",
          body: item.notes,
          payload: item.id,
        );
        print("Updated notification for item: ${item.id}");
      }

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
      List<WeddingDayScheduleModel1> reordered) async {
    if (userId == null) {
      throw StateError('User must be logged in to reorder items.');
    }

    final batch = _firestore.batch();
    final colRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('weddingDaySchedule1');

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

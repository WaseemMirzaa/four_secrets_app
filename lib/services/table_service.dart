import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/table_model.dart';

class TableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user ID or throw an error if not logged in
  String _getCurrentUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return userId;
  }

  Future<List<TableModel>> getTables() async {
    try {
      final userId = _getCurrentUserId();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tables')
          .get();
          
      return snapshot.docs
          .map((doc) => TableModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching tables: $e');
      rethrow;
    }
  }

  Future<void> addTable(TableModel table) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tables')
          .doc(table.id)
          .set(table.toJson());
    } catch (e) {
      print('Error adding table: $e');
      rethrow;
    }
  }

  Future<void> updateTable(TableModel table) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tables')
          .doc(table.id)
          .update(table.toJson());
    } catch (e) {
      print('Error updating table: $e');
      rethrow;
    }
  }

  Future<void> deleteTable(String tableId) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tables')
          .doc(tableId)
          .delete();
    } catch (e) {
      print('Error deleting table: $e');
      rethrow;
    }
  }

  Future<void> assignGuestToTable(String tableId, String guestId) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tables')
          .doc(tableId)
          .update({
        'assignedGuestIds': FieldValue.arrayUnion([guestId])
      });
    } catch (e) {
      print('Error assigning guest to table: $e');
      rethrow;
    }
  }

  Future<void> removeGuestFromTable(String tableId, String guestId) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tables')
          .doc(tableId)
          .update({
        'assignedGuestIds': FieldValue.arrayRemove([guestId])
      });
    } catch (e) {
      print('Error removing guest from table: $e');
      rethrow;
    }
  }
}

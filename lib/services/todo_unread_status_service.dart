import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodoUnreadStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Set todoUnreadStatus to true for a registered user
  static Future<void> setUnreadStatusForRegisteredUser(String userEmail) async {
    try {
      // Find user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userId = userQuery.docs.first.id;
        await _firestore.collection('users').doc(userId).update({
          'todoUnreadStatus': true,
        });
        print('✅ Set todoUnreadStatus=true for registered user: $userEmail');
      } else {
        print('❌ User not found in registered users: $userEmail');
      }
    } catch (e) {
      print('❌ Failed to set todoUnreadStatus for registered user: $e');
    }
  }

  /// Set todoUnreadStatus to false for the current user (mark as read)
  static Future<void> markAsReadForCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No current user to mark as read');
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'todoUnreadStatus': false,
      });
      print('✅ Marked todoUnreadStatus=false for current user: ${currentUser.email}');
    } catch (e) {
      print('❌ Failed to mark todoUnreadStatus as read: $e');
    }
  }

  /// Get the current user's todoUnreadStatus
  static Future<bool> getCurrentUserUnreadStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['todoUnreadStatus'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Failed to get todoUnreadStatus: $e');
      return false;
    }
  }

  /// Check if a user was previously invited (exists in non_registered_users)
  static Future<bool> wasUserPreviouslyInvited(String email) async {
    try {
      final nonRegisteredDoc = await _firestore
          .collection('non_registered_users')
          .doc(email)
          .get();
      
      return nonRegisteredDoc.exists;
    } catch (e) {
      print('❌ Error checking invitation status: $e');
      return false;
    }
  }

  /// Clean up non_registered_users entry when user signs up
  static Future<void> cleanupNonRegisteredUser(String email) async {
    try {
      await _firestore
          .collection('non_registered_users')
          .doc(email)
          .delete();
      print('🗑️ Removed user from non_registered_users collection: $email');
    } catch (e) {
      print('❌ Failed to cleanup non_registered_users entry: $e');
    }
  }

  /// Stream to listen to current user's todoUnreadStatus changes
  static Stream<bool> getCurrentUserUnreadStatusStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data()?['todoUnreadStatus'] ?? false;
      }
      return false;
    });
  }
}

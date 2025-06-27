import 'package:cloud_firestore/cloud_firestore.dart';

class NonRegisteredInviteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save an invite for a non-registered user
  Future<void> saveInvite({
    required String email, // The email being invited (not found in users)
    required String inviterEmail, // The email of the user sending the invite
    required String? inviterId, // The UID of the inviter (optional)
    required String? todoId, // The todoId or null if not relevant
    required String? todoName, // The todoName or null if not relevant
  }) async {
    await _firestore.collection('non_register_users').add({
      'email': email,
      'inviterEmail': inviterEmail,
      'inviterId': inviterId,
      'todoId': todoId,
      'todoName': todoName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch pending invites for a given email (when a user registers)
  Future<List<Map<String, dynamic>>> getPendingInvitesForEmail(
      String email) async {
    final snapshot = await _firestore
        .collection('non_register_users')
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Mark invite as accepted (when user registers and accepts)
  Future<void> markInviteAccepted(String inviteId) async {
    await _firestore.collection('non_register_users').doc(inviteId).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark invite as rejected (optional)
  Future<void> markInviteRejected(String inviteId) async {
    await _firestore.collection('non_register_users').doc(inviteId).update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}

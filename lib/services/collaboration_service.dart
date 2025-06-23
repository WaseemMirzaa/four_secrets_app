import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/collaboration_model.dart';
import '../model/to_do_model.dart';
import '../model/collaboration_todo_model.dart';
import 'collaboration_todo_service.dart';
import 'push_notification_service.dart';

class CollaborationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollaborationTodoService _collaborationTodoService =
      CollaborationTodoService();
  final PushNotificationService _pushNotificationService =
      PushNotificationService();

  String? get userId => _auth.currentUser?.uid;

  // Send collaboration invitation
  Future<void> sendInvitation({
    required String todoId,
    required String todoName,
    required String inviteeId,
    required String inviteeName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get inviter's name
    final inviterDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final inviterName = inviterDoc.data()?['name'] ?? 'Unknown';

    // Check if invitation already exists
    final existingInvitation = await _firestore
        .collection('invitations')
        .where('todoId', isEqualTo: todoId)
        .where('inviteeId', isEqualTo: inviteeId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingInvitation.docs.isNotEmpty) {
      throw Exception('Invitation already sent to this user');
    }

    // Create new invitation
    await _firestore.collection('invitations').add({
      'todoId': todoId,
      'todoName': todoName,
      'inviterId': currentUser.uid,
      'inviterName': inviterName,
      'inviteeId': inviteeId,
      'inviteeName': inviteeName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send push notification
    await _pushNotificationService.sendInvitationNotification(
      inviteeId: inviteeId,
      inviterName: inviterName,
      todoName: todoName,
    );
  }

  // Get sent invitations for the current user (no orderBy to avoid index requirement)
  Future<List<Map<String, dynamic>>> getSentInvitations() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await _firestore
        .collection('invitations')
        .where('inviterId', isEqualTo: currentUser.uid)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  // Get received invitations for the current user (no orderBy to avoid index requirement)
  Future<List<Map<String, dynamic>>> getReceivedInvitations() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await _firestore
        .collection('invitations')
        .where('inviteeId', isEqualTo: currentUser.uid)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  // Respond to an invitation
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get the invitation
    final invitationDoc =
        await _firestore.collection('invitations').doc(invitationId).get();
    if (!invitationDoc.exists) {
      throw Exception('Invitation not found');
    }

    final invitation = invitationDoc.data()!;
    if (invitation['inviteeId'] != currentUser.uid) {
      throw Exception('Not authorized to respond to this invitation');
    }

    if (invitation['status'] != 'pending') {
      throw Exception('Invitation is no longer pending');
    }

    // Update invitation status
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': accept ? 'accepted' : 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Send push notification
    if (accept) {
      await _pushNotificationService.sendInvitationAcceptedNotification(
        inviterId: invitation['inviterId'],
        inviteeName: invitation['inviteeName'],
        todoName: invitation['todoName'],
      );
    } else {
      await _pushNotificationService.sendInvitationRejectedNotification(
        inviterId: invitation['inviterId'],
        inviteeName: invitation['inviteeName'],
        todoName: invitation['todoName'],
      );
    }

    if (accept) {
      // Get the original todo
      final todoId = invitation['todoId'];
      final inviterId = invitation['inviterId'];
      final todoName = invitation['todoName'];
      final inviterName = invitation['inviterName'];

      if (todoId == null ||
          todoId.isEmpty ||
          inviterId == null ||
          inviterId.isEmpty) {
        throw Exception('Invalid todo or inviter information');
      }

      final todoDoc = await _firestore
          .collection('users')
          .doc(inviterId)
          .collection('todos')
          .doc(todoId)
          .get();

      if (!todoDoc.exists) {
        throw Exception('Todo not found');
      }

      final todo = ToDoModel.fromFirestore(todoDoc);

      // Create collaboration todo
      await _collaborationTodoService.createCollaborationTodo(
        todoId: todo.id!,
        todoName: todoName ??
            todo.toDoName, // Use the name from invitation or fallback to todo name
        ownerId: inviterId,
        ownerName: inviterName ??
            'Unknown', // Use the name from invitation or fallback to Unknown
        toDoItems: todo.toDoItems
            .map((item) => {'name': item['name'] as String, 'isChecked': false})
            .toList(),
      );
    }
  }

  // Check if user has access to a todo list
  Future<bool> hasAccess(String todoListId) async {
    if (userId == null) {
      return false;
    }

    // Check if user is the owner
    final todoDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoListId)
        .get();

    if (todoDoc.exists) {
      return true;
    }

    // Check if user has an accepted collaboration for this todoId
    final collaborationSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('collaborations')
        .where('todoId', isEqualTo: todoListId)
        .where('status', isEqualTo: 'accepted')
        .get();

    return collaborationSnapshot.docs.isNotEmpty;
  }

  // Get current user's name
  Future<String?> _getCurrentUserName() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data()?['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user name: $e');
      return 'Unknown User';
    }
  }

  // Delete an invitation
  Future<void> deleteInvitation(String invitationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get the invitation
    final invitationDoc =
        await _firestore.collection('invitations').doc(invitationId).get();
    if (!invitationDoc.exists) {
      throw Exception('Invitation not found');
    }

    final invitation = invitationDoc.data()!;
    if (invitation['inviterId'] != currentUser.uid) {
      throw Exception('Not authorized to delete this invitation');
    }

    // Delete the invitation
    await _firestore.collection('invitations').doc(invitationId).delete();

    // Send push notification to invitee
    await _pushNotificationService.sendNotification(
      userId: invitation['inviteeId'],
      title: 'Invitation Revoked',
      body:
          'Your invitation to collaborate on "${invitation['todoName']}" has been revoked',
      data: {
        'type': 'invitation_revoked',
        'todoName': invitation['todoName'],
      },
    );
  }

  // Leave a collaboration
  Future<void> leaveCollaboration(String todoId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get all todos where the user is a collaborator
      final todoSnapshot = await _firestore
          .collectionGroup('todos')
          .where('collaborators', arrayContains: currentUser.uid)
          .get();

      // Find the specific todo
      final todoDoc = todoSnapshot.docs.firstWhere(
        (doc) => doc.id == todoId,
        orElse: () => throw Exception('Todo not found'),
      );

      final todoData = todoDoc.data();
      if (todoData['userId'] == currentUser.uid) {
        throw Exception('Owner cannot leave their own todo list');
      }

      // Get the owner's user ID from the todo data
      final ownerId = todoData['userId'];

      // Remove user from collaborators
      await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('todos')
          .doc(todoId)
          .update({
        'collaborators': FieldValue.arrayRemove([currentUser.uid]),
      });
      print(
          'User ${currentUser.uid} removed from collaborators of todo $todoId');

      // Delete any pending invitations for this todo
      final invitations = await _firestore
          .collection('invitations')
          .where('todoId', isEqualTo: todoId)
          .where('inviteeId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in invitations.docs) {
        await doc.reference.delete();
      }
      print('Deleted ${invitations.docs.length} pending invitations');
    } catch (e) {
      print('Error leaving collaboration: $e');
      throw Exception('Error leaving collaboration: $e');
    }
  }

  // Debug method to check all invitations (temporary - remove in production)
  Future<void> debugAllInvitations() async {
    try {
      final snapshot = await _firestore.collection('invitations').get();
      print('=== ALL INVITATIONS DEBUG ===');
      print('Total invitations in collection: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('ID: ${doc.id}');
        print('Data: $data');
        print('---');
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error in debug: $e');
    }
  }
}

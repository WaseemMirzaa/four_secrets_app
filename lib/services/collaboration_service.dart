import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/collaboration_model.dart';
import '../model/to_do_model.dart';
import 'push_notification_service.dart';
import 'email_service.dart';

class CollaborationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

    // Remove inviteeId from revokedFor if present
    final todoRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('todos')
        .doc(todoId);
    final todoDoc = await todoRef.get();
    final data = todoDoc.data();
    if (data != null &&
        (data['revokedFor'] as List?)?.contains(inviteeId) == true) {
      await todoRef.update({
        'revokedFor': FieldValue.arrayRemove([inviteeId]),
      });
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

    String finalTodoName = todoName;
    // Fallback: If todoName is empty, fetch from Firestore (first category name)
    if (finalTodoName.isEmpty) {
      final todoDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('todos')
          .doc(todoId)
          .get();
      if (todoDoc.exists) {
        final data = todoDoc.data();
        if (data != null &&
            data['categories'] != null &&
            data['categories'] is List &&
            (data['categories'] as List).isNotEmpty) {
          final firstCategory = (data['categories'] as List)[0];
          if (firstCategory is Map &&
              firstCategory['categoryName'] != null &&
              firstCategory['categoryName'].toString().isNotEmpty) {
            finalTodoName = firstCategory['categoryName'];
          }
        }
      }
    }
    print('DEBUG: Creating invitation for todoId: '
        '\x1B[33m$todoId\x1B[0m, todoName: \x1B[32m$finalTodoName\x1B[0m');

    // Create new invitation
    await _firestore.collection('invitations').add({
      'todoId': todoId,
      'todoName': finalTodoName,
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
      todoName: finalTodoName,
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
        .where('inviterEmail', isEqualTo: currentUser.email)
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
        .where('inviteeEmail', isEqualTo: currentUser.email)
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
    if (invitation['inviteeEmail'] != currentUser.email) {
      throw Exception('Not authorized to respond to this invitation');
    }

    if (invitation['status'] != 'pending') {
      throw Exception('Invitation is not pending');
    }

    final ownerEmail = invitation['inviterEmail'];
    final todoId = invitation['todoId'];

    print(
        '[Collab Debug] Accepting invite for todoId: $todoId, ownerEmail: $ownerEmail, receiver: ${currentUser.email}');

    if (accept) {
      // Add the receiver to the collaborators array and set isShared: true
      // Find the owner's userId by email
      final ownerQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: ownerEmail)
          .limit(1)
          .get();
      if (ownerQuery.docs.isEmpty) {
        throw Exception('Owner not found');
      }
      final ownerId = ownerQuery.docs.first.id;
      final todoRef = _firestore
          .collection('users')
          .doc(ownerId)
          .collection('todos')
          .doc(todoId);
      if (currentUser.email != ownerEmail) {
        await todoRef.update({
          'collaborators': FieldValue.arrayUnion([currentUser.email]),
          'isShared': true,
          'revokedFor': FieldValue.arrayRemove([currentUser.email]),
        });
        // Add the receiver to the owner's globalCollaborators array (by email)
        await _firestore.collection('users').doc(ownerId).update({
          'globalCollaborators': FieldValue.arrayUnion([currentUser.email]),
        });
      }
      // Fetch and print the updated todo document for debugging
      final updatedDoc = await todoRef.get();
      print('[Collab Debug] Updated todo after accepting invite:');
      print(updatedDoc.data());
      await invitationDoc.reference.update({'status': 'accepted'});
    } else {
      await invitationDoc.reference.update({'status': 'declined'});
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
          .where('inviteeEmail', isEqualTo: currentUser.email)
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

  // Send collaboration invitation for ALL todos
  Future<void> sendInvitationForAllTodos({
    required String inviteeEmail,
    String? inviteeName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get inviter's name
    final inviterDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final inviterName = inviterDoc.data()?['name'] ?? 'Unknown';

    // Get all todos for the current user
    final todosSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('todos')
        .get();
    final todos =
        todosSnapshot.docs.map((doc) => ToDoModel.fromFirestore(doc)).toList();
    if (todos.isEmpty) {
      throw Exception('No todos to share');
    }
    final todoIds = todos.map((t) => t.id).toList();
    final todoNames = todos.map((t) => t.toDoName ?? '').toList();
    final todoCount = todos.length;
    // Collect all categories for each todo (as a map, not nested arrays)
    final todoCategories = todos
        .map((t) => {
              'todoId': t.id,
              'categories': t.categories ?? [],
            })
        .toList();

    // Check if invitation already exists for this inviteeEmail (for all todos)
    final existingInvitation = await _firestore
        .collection('invitations')
        .where('inviterEmail', isEqualTo: currentUser.email)
        .where('inviteeEmail', isEqualTo: inviteeEmail)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existingInvitation.docs.isNotEmpty) {
      throw Exception('Invitation already sent to this email');
    }

    // Create new invitation for all todos, now including categories
    await _firestore.collection('invitations').add({
      'todoIds': todoIds,
      'todoNames': todoNames,
      'todoCount': todoCount,
      'todoCategories': todoCategories, // <-- include categories
      'inviterEmail': currentUser.email,
      'inviterName': inviterName,
      'inviteeEmail': inviteeEmail,
      'inviteeName': inviteeName ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send email invitation
    if (inviteeEmail.isNotEmpty) {
      final emailService = EmailService();
      final subject = 'Invitation to collaborate';
      final message = '$inviterName has invited you to collaborate on: ' +
          (todoCount == 1 ? todoNames.first : todoNames.join(', '));
      try {
        await emailService.sendEmail(
          email: inviteeEmail,
          subject: subject,
          message: message,
        );
      } catch (e) {
        print('Failed to send invitation email: $e');
      }
    }
  }

  // Respond to an invitation (for ALL todos)
  Future<void> respondToInvitationForAllTodos(
      String invitationId, bool accept) async {
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
    if (invitation['inviteeEmail'] != currentUser.email) {
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

    // Send push notification (optional, can be updated to use email)
    // ... existing code ...

    // If accepted, add the receiver to the collaborators array of each todo
    final ownerEmail = invitation['inviterEmail'];
    final todoIds = List<String>.from(invitation['todoIds'] ?? []);
    // Find the owner's userId by email
    final ownerQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: ownerEmail)
        .limit(1)
        .get();
    if (ownerQuery.docs.isEmpty) {
      throw Exception('Owner not found');
    }
    final ownerId = ownerQuery.docs.first.id;
    for (final todoId in todoIds) {
      final todoRef = _firestore
          .collection('users')
          .doc(ownerId)
          .collection('todos')
          .doc(todoId);
      // Always add email to collaborators, and set ownerEmail if not present
      final todoDoc = await todoRef.get();
      final todoData = todoDoc.data() ?? {};
      if (currentUser.email != ownerEmail) {
        final updates = {
          'collaborators': FieldValue.arrayUnion([currentUser.email]),
          'isShared': true,
          'revokedFor': FieldValue.arrayRemove([currentUser.email]),
        };
        if (todoData['ownerEmail'] == null && ownerEmail != null) {
          updates['ownerEmail'] = ownerEmail;
        }
        await todoRef.update(updates);
      }
      // Debug print
      final updatedDoc = await todoRef.get();
      print('[Collab Debug] Updated todo after accepting invite (multi):');
      print(updatedDoc.data());
    }
    // Add the receiver to the owner's globalCollaborators array (by email)
    if (currentUser.email != ownerEmail) {
      await _firestore.collection('users').doc(ownerId).update({
        'globalCollaborators': FieldValue.arrayUnion([currentUser.email]),
      });
    }
  }

  // Remove all collaborators from a todo list (revoke access for all)
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
    final prevCollaborators = List<String>.from(todo.collaborators);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .update({
      'collaborators': [],
      'isShared': false,
      'revokedFor': FieldValue.arrayUnion(prevCollaborators),
    });
  }
}

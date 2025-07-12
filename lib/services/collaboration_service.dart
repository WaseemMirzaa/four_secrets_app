import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/to_do_model.dart';
import 'email_service.dart';
import 'push_notification_service.dart';

class CollaborationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final EmailService _emailService = EmailService();
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
      throw Exception('Einladung wurde bereits an diesen Benutzer gesendet');
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
      // Only update invitation status, do NOT remove from revokedFor or add to collaborators
      await invitationDoc.reference.update({'status': 'declined'});
      // Notify the inviter that their invitation was declined
      if (invitation['inviterId'] != null) {
        await _pushNotificationService.sendNotification(
          userId: invitation['inviterId'],
          title: 'Einladung abgelehnt',
          body: '${currentUser.email} hat deine Einladung abgelehnt.',
          data: {'type': 'invitation_declined'},
        );
      }
    }
  }

  // Check if user has access to a todo list
  Future<bool> hasAccess(String todoListId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    // Fetch all todos in the collection group, then find the one with the matching ID
    final todoSnapshot = await _firestore.collectionGroup('todos').get();

    QueryDocumentSnapshot<Map<String, dynamic>>? todoDoc;
    for (final doc in todoSnapshot.docs) {
      if (doc.id == todoListId) {
        todoDoc = doc;
        break;
      }
    }

    if (todoDoc == null) return false;

    final todoData = todoDoc.data();
    final collaborators = List<String>.from(todoData['collaborators'] ?? []);
    final revokedFor = List<String>.from(todoData['revokedFor'] ?? []);

    // Allow if owner (by UID), or collaborator (by email, not revoked)
    if (todoData['userId'] == user.uid ||
        (collaborators.contains(user.email) &&
            !revokedFor.contains(user.email))) {
      return true;
    }
    return false;
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
  // Future<void> deleteInvitation(String invitationId) async {
  //   // final currentUser = _auth.currentUser;
  //   // if (currentUser == null) {
  //   //   throw Exception('User not authenticated');
  //   // }

  //   // Get the invitation
  //   final invitationDoc =
  //       await _firestore.collection('invitations').doc(invitationId).get();
  //   if (!invitationDoc.exists) {
  //     throw Exception('Invitation not found');
  //   }

  //   final invitation = invitationDoc.data()!;
  //   print('Invitation Data = $invitation');
  //   // print('Invitation Data curr uid  = ${currentUser.uid}');
  //   // if (invitation['inviterId'] != currentUser.uid) {
  //   //   throw Exception('Not authorized to delete this invitation');
  //   // }

  //   // Delete the invitation
  //    _firestore.collection('invitations').doc(invitationId).delete();
  //    _emailService.sendRevokeAccessEmail(
  //       email: invitation['inviteeEmail'],
  //       inviterName: invitation['inviterName']);
  // }
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
    print('Invitation Data = $invitation');
    if (invitation['inviterId'] != currentUser.uid &&
        invitation['inviterEmail'] != currentUser.email) {
      throw Exception('Not authorized to delete this invitation');
    }

    final todoIds = List<String>.from(invitation['todoIds'] ?? []);
    final inviteeEmail = invitation['inviteeEmail'] as String;
    final inviterName = invitation['inviterName'] as String? ?? 'Unknown';

    // Use a batch for atomic updates
    final batch = _firestore.batch();

    // Update each to-do: remove invitee from collaborators, add to revokedFor
    for (final todoId in todoIds) {
      final todoRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('todos')
          .doc(todoId);
      final todoDoc = await todoRef.get();
      if (!todoDoc.exists) {
        print('Todo $todoId not found, skipping');
        continue;
      }
      final todo = ToDoModel.fromFirestore(todoDoc);
      if (todo.userId != currentUser.uid) {
        throw Exception('Only the owner can revoke access for todo $todoId');
      }
      final updatedCollaborators = List<String>.from(todo.collaborators)
        ..remove(inviteeEmail);
      final updatedRevokedFor = List<String>.from(todo.revokedFor)
        ..add(inviteeEmail);
      final updatedTodo = todo.copyWith(
        collaborators: updatedCollaborators,
        revokedFor: updatedRevokedFor,
        isShared: updatedCollaborators.isNotEmpty,
      );
      batch.update(todoRef, updatedTodo.toMap());
    }

    // Delete the invitation
    batch.delete(_firestore.collection('invitations').doc(invitationId));

    // Remove from globalCollaborators
    final userRef = _firestore.collection('users').doc(currentUser.uid);
    batch.update(userRef, {
      'globalCollaborators': FieldValue.arrayRemove([inviteeEmail]),
    });

    // Commit the batch
    try {
      await batch.commit();
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Batch committed successfully');
    } catch (e) {
      print(
          '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Error committing batch: $e');
      rethrow;
    }

    // Send revocation email to the invitee
    try {
      await _emailService.sendRevokeAccessEmail(
        email: inviteeEmail,
        inviterName: inviterName,
      );
      print(
          '[EMAIL_LOG] ${DateTime.now().millisecondsSinceEpoch}: Revoke access email sent to $inviteeEmail');
    } catch (e) {
      print(
          '[EMAIL_LOG] ${DateTime.now().millisecondsSinceEpoch}: Error sending revoke access email to $inviteeEmail: $e');
    }

    print(
        '[COLLAB_LOG] ${DateTime.now().millisecondsSinceEpoch}: Invitation $invitationId revoked successfully');
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
        await _emailService.sendRevokeAccessEmail(
            email: doc.data()['inviteeEmail'],
            inviterName: doc.data()['inviterName']);
        await _pushNotificationService.sendNotification(
          userId: doc.data()['inviteeId'],
          title: 'Einladung storniert',
          body:
              'Ihre Einladung zur Zusammenarbeit auf "${doc.data()['todoName']}" wurde storniert',
          data: {'type': 'invitation_revoked'},
        );
      }
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

    // Prevent sending invitation to self
    if (inviteeEmail.trim().toLowerCase() ==
        currentUser.email?.trim().toLowerCase()) {
      throw Exception('You cannot invite yourself.');
    }

    // Get inviter's name
    final inviterDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final inviterName = inviterDoc.data()?['name'] ?? 'Unknown';

    // Fetch the invitee's FCM token
    String? inviteeFcmToken;
    try {
      final inviteeQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: inviteeEmail)
          .limit(1)
          .get();
      if (inviteeQuery.docs.isNotEmpty) {
        inviteeFcmToken = inviteeQuery.docs.first.data()['fcmToken'];
      }
    } catch (e) {
      print('Error fetching invitee FCM token: $e');
    }

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
      throw Exception('Einladung wurde bereits an diese E-Mail gesendet');
    }

    // Create new invitation for all todos, now including categories
    await _firestore.collection('invitations').add({
      'todoIds': todoIds,
      'todoNames': todoNames,
      'todoCount': todoCount,
      'todoCategories': todoCategories,
      'inviterEmail': currentUser.email,
      'inviterName': inviterName,
      'inviteeEmail': inviteeEmail,
      'inviteeName': inviteeName ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Only send notification if inviteeFcmToken is found
    if (inviteeFcmToken != null && inviteeFcmToken.isNotEmpty) {
      await _firestore.collection('notifications').add({
        'token': inviteeFcmToken,
        'toEmail': inviteeEmail,
        'title': 'Einladung zur Zusammenarbeit',
        'body':
            '$inviterName hat Sie eingeladen, an folgendem/followenden Element(en) zusammenzuarbeiten: ' +
                (todoCount == 1 ? todoNames.first : todoNames.join(', ')),
        'data': {'type': 'invitation', 'toEmail': inviteeEmail},
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } else {
      print(
          'No FCM token found for invitee $inviteeEmail, notification not sent.');
    }

    // Send email invitation
    // if (inviteeEmail.isNotEmpty) {
    //   final emailService = EmailService();
    //   final subject = 'Einladung zur Zusammenarbeit';
    //   final message =
    //       '$inviterName hat Sie eingeladen, an folgendem/followenden Element(en) zusammenzuarbeiten: ' +
    //           (todoCount == 1 ? todoNames.first : todoNames.join(', '));
    //   try {
    //     await emailService.sendEmail(
    //       email: inviteeEmail,
    //       subject: subject,
    //       message: message,
    //     );
    //   } catch (e) {
    //     print('Failed to send invitation email: $e');
    //   }
    // }
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

    if (accept) {
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
          await _pushNotificationService.sendNotification(
            userId: todoId,
            title: 'Zugriff erhalten',
            body:
                'Du hast Zugriff auf die Liste "${todoData['toDoName']}" erhalten',
            data: {'type': 'access_granted'},
          );
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
    } else {
      // Notify the inviter that their invitation was declined
      if (invitation['inviterId'] != null) {
        await _pushNotificationService.sendNotification(
          userId: invitation['inviterId'],
          title: 'Einladung abgelehnt',
          body: '${currentUser.email} hat deine Einladung abgelehnt.',
          data: {'type': 'invitation_declined'},
        );
      }
      print("${invitation['inviterId']}  ");
    }
    // If declined, do NOT add to collaborators or remove from revokedFor
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
    final prevCollaborators = List<String>.from(todo.collaborators)
      ..removeWhere((email) => email == todo.ownerEmail);
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

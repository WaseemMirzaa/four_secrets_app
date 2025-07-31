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
    String? inviteeEmail, // Add email parameter
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

    // Check if invitation already exists (check by email for consistency)
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

    // Get invitee email if not provided
    String finalInviteeEmail = inviteeEmail ?? '';
    if (finalInviteeEmail.isEmpty && inviteeId.isNotEmpty) {
      // Look up invitee email by ID
      try {
        final inviteeDoc =
            await _firestore.collection('users').doc(inviteeId).get();
        if (inviteeDoc.exists) {
          finalInviteeEmail = inviteeDoc.data()?['email'] ?? '';
        }
      } catch (e) {
        print('Error fetching invitee email: $e');
      }
    }

    // Create new invitation with email fields
    await _firestore.collection('invitations').add({
      'todoId': todoId,
      'todoName': finalTodoName,
      'inviterId': currentUser.uid,
      'inviterEmail': currentUser.email, // Add inviter email
      'inviterName': inviterName,
      'inviteeId': inviteeId,
      'inviteeEmail': finalInviteeEmail, // Add invitee email
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
    print(
        '🔵 [DEBUG] respondToInvitation called with invitationId: $invitationId, accept: $accept');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('🔴 [ERROR] User not authenticated');
      throw Exception('User not authenticated');
    }
    print('🔵 [DEBUG] Current user: ${currentUser.email} (${currentUser.uid})');

    // Get the invitation
    print('🔵 [DEBUG] Fetching invitation document from Firestore...');
    final invitationDoc =
        await _firestore.collection('invitations').doc(invitationId).get();
    if (!invitationDoc.exists) {
      print(
          '🔴 [ERROR] Invitation document not found in Firestore for ID: $invitationId');
      throw Exception('Invitation not found');
    }
    print('🔵 [DEBUG] Invitation document found successfully');

    final invitation = invitationDoc.data()!;
    print('🔵 [DEBUG] Invitation data: $invitation');

    if (invitation['inviteeEmail'] != currentUser.email) {
      print(
          '🔴 [ERROR] Not authorized - inviteeEmail: ${invitation['inviteeEmail']}, currentUser: ${currentUser.email}');
      throw Exception('Not authorized to respond to this invitation');
    }

    if (invitation['status'] != 'pending') {
      print(
          '🔴 [ERROR] Invitation status is not pending: ${invitation['status']}');
      throw Exception('Invitation is not pending');
    }

    final ownerEmail = invitation['inviterEmail'];
    final todoId = invitation['todoId'];
    print(
        '🔵 [DEBUG] Processing invitation - ownerEmail: $ownerEmail, todoId: $todoId');

    print(
        '[Collab Debug] Accepting invite for todoId: $todoId, ownerEmail: $ownerEmail, receiver: ${currentUser.email}');

    if (accept) {
      print(
          '🔵 [DEBUG] Accepting invitation - looking up owner by email: $ownerEmail');
      // Add the receiver to the collaborators array and set isShared: true
      // Find the owner's userId by email
      final ownerQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: ownerEmail)
          .limit(1)
          .get();
      if (ownerQuery.docs.isEmpty) {
        print('🔴 [ERROR] Owner not found for email: $ownerEmail');
        throw Exception('Owner not found');
      }
      print('🔵 [DEBUG] Owner found: ${ownerQuery.docs.first.id}');
      final ownerId = ownerQuery.docs.first.id;
      final todoRef = _firestore
          .collection('users')
          .doc(ownerId)
          .collection('todos')
          .doc(todoId);

      print(
          '🔵 [DEBUG] Accessing todo document at path: users/$ownerId/todos/$todoId');

      // Check if todo document exists before updating
      final todoDoc = await todoRef.get();
      if (!todoDoc.exists) {
        print(
            '🔴 [ERROR] Todo document not found at path: users/$ownerId/todos/$todoId');
        throw Exception('Todo document not found');
      }
      print('🔵 [DEBUG] Todo document found, current data: ${todoDoc.data()}');

      if (currentUser.email != ownerEmail) {
        print(
            '🔵 [DEBUG] Updating todo document with collaborator: ${currentUser.email}');
        await todoRef.update({
          'collaborators': FieldValue.arrayUnion([currentUser.email]),
          'isShared': true,
          'revokedFor': FieldValue.arrayRemove([currentUser.email]),
        });
        print('🔵 [DEBUG] Todo document updated successfully');

        // Add the receiver to the owner's globalCollaborators array (by email)
        print('🔵 [DEBUG] Updating owner globalCollaborators');
        await _firestore.collection('users').doc(ownerId).update({
          'globalCollaborators': FieldValue.arrayUnion([currentUser.email]),
        });
        print('🔵 [DEBUG] Owner globalCollaborators updated successfully');
      } else {
        print('🔵 [DEBUG] Skipping update - user is the owner');
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

  // NEW SIMPLE REVOKE: Delete invitation to revoke access
  Future<void> revokeInvitation(String invitationId) async {
    try {
      print('🔵 [DEBUG] Revoking invitation: $invitationId');

      // Simply delete the invitation document
      await _firestore.collection('invitations').doc(invitationId).delete();

      print('🔵 [DEBUG] Invitation revoked successfully');
    } catch (e) {
      print('🔴 [ERROR] Failed to revoke invitation: $e');
      throw e;
    }
  }

  // NEW SIMPLE REVOKE: Delete all invitations for a specific user
  Future<void> revokeAllInvitationsForUser(String inviteeEmail) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('🔵 [DEBUG] Revoking all invitations for user: $inviteeEmail');

      // Find all invitations sent by current user to the specified user
      final invitationsSnapshot = await _firestore
          .collection('invitations')
          .where('inviterEmail', isEqualTo: currentUser.email)
          .where('inviteeEmail', isEqualTo: inviteeEmail)
          .where('status', isEqualTo: 'accepted')
          .get();

      print(
          '🔵 [DEBUG] Found ${invitationsSnapshot.docs.length} invitations to revoke');

      // Delete all found invitations
      for (var doc in invitationsSnapshot.docs) {
        await doc.reference.delete();
        print('🔵 [DEBUG] Deleted invitation: ${doc.id}');
      }

      print('🔵 [DEBUG] All invitations revoked successfully');
    } catch (e) {
      print('🔴 [ERROR] Failed to revoke all invitations: $e');
      throw e;
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

    // Fetch the invitee's FCM token and check if user is registered
    String? inviteeFcmToken;
    bool isUserRegistered = false;
    String? inviteeUserId;
    try {
      final inviteeQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: inviteeEmail)
          .limit(1)
          .get();
      if (inviteeQuery.docs.isNotEmpty) {
        final inviteeDoc = inviteeQuery.docs.first;
        inviteeFcmToken = inviteeDoc.data()['fcmToken'];
        isUserRegistered = true;
        inviteeUserId = inviteeDoc.id;
        print('📧 User is registered: $inviteeEmail (ID: $inviteeUserId)');
      } else {
        print('📧 User is NOT registered: $inviteeEmail');
      }
    } catch (e) {
      print('Error fetching invitee data: $e');
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

    // Set todoUnreadStatus to true for the invitee
    if (isUserRegistered && inviteeUserId != null) {
      // User is registered - update their user document
      try {
        await _firestore.collection('users').doc(inviteeUserId).update({
          'todoUnreadStatus': true,
        });
        print('✅ Set todoUnreadStatus=true for registered user: $inviteeEmail');
      } catch (e) {
        print('❌ Failed to set todoUnreadStatus for registered user: $e');
      }
    } else {
      // User is not registered - this will be handled in the todo page when saving to non_registered_users
      print(
          '📝 todoUnreadStatus will be set when saving to non_registered_users collection');
    }

    // Only send notification if inviteeFcmToken is found
    if (inviteeFcmToken != null && inviteeFcmToken.isNotEmpty) {
      // Send notification via external API
      final pushService = PushNotificationService();
      await pushService.sendNotificationByEmail(
        email: inviteeEmail,
        title: 'Einladung zur Zusammenarbeit',
        body:
            '$inviterName hat Sie eingeladen, an folgendem/followenden Element(en) zusammenzuarbeiten: ' +
                (todoCount == 1 ? todoNames.first : todoNames.join(', ')),
        data: {'type': 'invitation', 'toEmail': inviteeEmail},
      );
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
    print(
        '🔵 [DEBUG] respondToInvitationForAllTodos called with invitationId: $invitationId, accept: $accept');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print(
          '🔴 [ERROR] User not authenticated in respondToInvitationForAllTodos');
      throw Exception('User not authenticated');
    }
    print(
        '🔵 [DEBUG] Current user in respondToInvitationForAllTodos: ${currentUser.email} (${currentUser.uid})');

    // Get the invitation
    print('🔵 [DEBUG] Fetching invitation document for ALL todos...');
    final invitationDoc =
        await _firestore.collection('invitations').doc(invitationId).get();
    if (!invitationDoc.exists) {
      print(
          '🔴 [ERROR] Invitation document not found for ALL todos with ID: $invitationId');
      throw Exception('Invitation not found');
    }
    print('🔵 [DEBUG] Invitation document found for ALL todos');

    final invitation = invitationDoc.data()!;
    print('🔵 [DEBUG] Invitation data for ALL todos: $invitation');

    if (invitation['inviteeEmail'] != currentUser.email) {
      print(
          '🔴 [ERROR] Not authorized for ALL todos - inviteeEmail: ${invitation['inviteeEmail']}, currentUser: ${currentUser.email}');
      throw Exception('Not authorized to respond to this invitation');
    }
    if (invitation['status'] != 'pending') {
      print(
          '🔴 [ERROR] Invitation status is not pending for ALL todos: ${invitation['status']}');
      throw Exception('Invitation is no longer pending');
    }

    // Update invitation status
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': accept ? 'accepted' : 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    if (accept) {
      // If accepted, add the receiver to the collaborators array of ALL current todos
      final ownerEmail = invitation['inviterEmail'];
      print(
          '🔵 [DEBUG] Processing ALL todos acceptance - ownerEmail: $ownerEmail');

      // Find the owner's userId by email
      print('🔵 [DEBUG] Looking up owner by email for ALL todos: $ownerEmail');
      final ownerQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: ownerEmail)
          .limit(1)
          .get();
      if (ownerQuery.docs.isEmpty) {
        print(
            '🔴 [ERROR] Owner not found for ALL todos with email: $ownerEmail');
        throw Exception('Owner not found');
      }
      final ownerId = ownerQuery.docs.first.id;
      print('🔵 [DEBUG] Owner found for ALL todos: $ownerId');

      // Fetch ALL current todos from the owner (not just the ones in invitation)
      print('🔵 [DEBUG] Fetching ALL current todos from owner...');
      final allTodosSnapshot = await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('todos')
          .get();

      final currentTodoIds =
          allTodosSnapshot.docs.map((doc) => doc.id).toList();
      print(
          '🔵 [DEBUG] Found ${currentTodoIds.length} current todos: $currentTodoIds');
      for (final todoId in currentTodoIds) {
        print('🔵 [DEBUG] Processing todo: $todoId');
        final todoRef = _firestore
            .collection('users')
            .doc(ownerId)
            .collection('todos')
            .doc(todoId);

        print(
            '🔵 [DEBUG] Accessing todo document at path: users/$ownerId/todos/$todoId');

        // Check if todo document exists before updating
        final todoDoc = await todoRef.get();
        if (!todoDoc.exists) {
          print(
              '🔴 [ERROR] Todo document not found at path: users/$ownerId/todos/$todoId');
          continue; // Skip this todo and continue with others
        }

        final todoData = todoDoc.data() ?? {};
        print('🔵 [DEBUG] Todo document found, current data: $todoData');

        if (currentUser.email != ownerEmail) {
          print(
              '🔵 [DEBUG] Updating todo document with collaborator: ${currentUser.email}');
          final updates = {
            'collaborators': FieldValue.arrayUnion([currentUser.email]),
            'isShared': true,
            'revokedFor': FieldValue.arrayRemove([currentUser.email]),
          };
          if (todoData['ownerEmail'] == null && ownerEmail != null) {
            updates['ownerEmail'] = ownerEmail;
          }

          await todoRef.update(updates);
          print('🔵 [DEBUG] Todo document updated successfully');

          // Verify the update was successful
          final verifyDoc = await todoRef.get();
          if (verifyDoc.exists) {
            final verifyData = verifyDoc.data()!;
            print(
                '🔵 [DEBUG] Verification - Updated collaborators: ${verifyData['collaborators']}');
            print(
                '🔵 [DEBUG] Verification - isShared: ${verifyData['isShared']}');
            print(
                '🔵 [DEBUG] Verification - revokedFor: ${verifyData['revokedFor']}');
          }
        } else {
          print('🔵 [DEBUG] Skipping update - user is the owner');
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

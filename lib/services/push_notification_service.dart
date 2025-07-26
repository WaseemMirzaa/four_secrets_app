import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for shared notification stream

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize the service
  Future<void> initialize() async {
    try {
      // Initialize local notifications first
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('notificationicon');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotifications.initialize(initSettings);

      // Create notification channel for Android
      await _createNotificationChannel();

      // Request permission for notifications with retry mechanism
      bool permissionsGranted = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!permissionsGranted && retryCount < maxRetries) {
        try {
          final settings = await _messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            print('🟢 FCM: Notification permissions granted');
            permissionsGranted = true;
          } else {
            print(
                '🟡 FCM: Notification permissions not granted: ${settings.authorizationStatus}');
            throw Exception('Notification permissions not granted');
          }
        } catch (e) {
          retryCount++;
          print('🟡 FCM: Permission request attempt $retryCount failed: $e');
          if (retryCount >= maxRetries) {
            print(
                '🔴 FCM: Failed to get notification permissions after $maxRetries attempts');
            break;
          }
          await Future.delayed(Duration(seconds: 1));
        }
      }

      // Handle incoming messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🟢 FCM: Received foreground message');
        try {
          _showNotification(
            title: message.notification?.title ?? 'New Notification',
            body: message.notification?.body ?? '',
          );
        } catch (e) {
          print('🔴 FCM: Error showing notification: $e');
        }
      });

      print('🟢 FCM: Initialization completed successfully');
    } catch (e) {
      print('🔴 FCM: Error during initialization: $e');
      // Don't throw the error, just log it to prevent app crashes
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'wedding_schedule_channel',
      'Wedding Notifications',
      description: 'Notifications for wedding events',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      print('🟢 FCM: Notification channel created');
    } catch (e) {
      print('🔴 FCM: Error creating notification channel: $e');
    }
  }

  // Show local notification
  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'collaboration_channel',
      'Collaboration Notifications',
      channelDescription: 'Notifications for collaboration events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }

  // Send notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get the user's FCM token and email
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final String? fcmToken = userDoc.data()?['fcmToken'];
      final String? email = userDoc.data()?['email'];

      if (fcmToken == null) {
        print('No FCM token found for user $userId');
        return;
      }

      // Send the notification using Cloud Functions
      await _firestore.collection('notifications').add({
        'token': fcmToken,
        'toEmail': email,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send collaboration invitation notification
  Future<void> sendInvitationNotification({
    required String inviteeId,
    required String inviterName,
    required String todoName,
  }) async {
    await sendNotification(
      userId: inviteeId,
      title: 'Neue Zusammenarbeitseinladung',
      body: '$inviterName hat dich eingeladen, an "$todoName" mitzuarbeiten',
      data: {
        'type': 'invitation',
        'todoName': todoName,
      },
    );
  }

  // Send invitation acceptance notification
  Future<void> sendInvitationAcceptedNotification({
    required String inviterId,
    required String inviteeName,
    required String todoName,
  }) async {
    await sendNotification(
      userId: inviterId,
      title: 'Einladung akzeptiert',
      body:
          '$inviteeName hat deine Einladung zur Zusammenarbeit an "$todoName" akzeptiert',
      data: {
        'type': 'invitation_accepted',
        'todoName': todoName,
      },
    );
  }

  // Send invitation rejection notification
  Future<void> sendInvitationRejectedNotification({
    required String inviterId,
    required String inviteeName,
  }) async {
    await sendNotification(
      userId: inviterId,
      title: 'Einladung abgelehnt',
      body: '$inviteeName hat deine Einladung zur Zusammenarbeit',
      data: {
        'type': 'invitation_rejected',
      },
    );
  }

  // Send comment notification
  Future<void> sendCommentNotification({
    required String todoOwnerId,
    required String commenterName,
    required String todoName,
    required String comment,
  }) async {
    await sendNotification(
      userId: todoOwnerId,
      title: 'Neuer Kommentar',
      body: '$commenterName hat "$todoName" kommentiert: $comment',
      data: {
        'type': 'comment',
        'todoName': todoName,
      },
    );
  }

  // Send deletion notification
  Future<void> sendCollaborationDeletedNotification({
    required String collaboratorId,
    required String ownerName,
    required String todoName,
  }) async {
    await sendNotification(
      userId: collaboratorId,
      title: 'Zusammenarbeit beendet',
      body: '$ownerName hat die Zusammenarbeit an $todoName beendet',
      data: {
        'type': 'collaboration_deleted',
        'todoName': todoName,
      },
    );
  }

// Alternative method without permission check for debugging
  Future<String?> getFcmTokenDirect() async {
    try {
      print('🟡 Getting FCM token directly (no permission check)...');
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        print('🟢 Direct FCM token: ${fcmToken.substring(0, 20)}...');
      } else {
        print('🔴 Direct FCM token is null');
      }

      return fcmToken;
    } catch (e) {
      print('🔴 Error getting direct FCM token: $e');
      return null;
    }
  }

  // Send notification to a specific user by email
  Future<void> sendNotificationByEmail({
    required String email,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Query the user by email
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        print('No user found with email $email');
        return;
      }
      final userDoc = query.docs.first;
      final String? fcmToken = userDoc.data()['fcmToken'];

      if (fcmToken == null) {
        print('No FCM token found for user with email $email');
        return;
      }

      // Send the notification using Cloud Functions
      await _firestore.collection('notifications').add({
        'token': fcmToken,
        'toEmail': email,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending notification by email: $e');
    }
  }

  // Shared notification stream for red dots across all screens
  static Stream<bool> get hasNewCollabNotificationStream async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield false;
      return;
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final userEmail = user.email;
    if (fcmToken == null && userEmail == null) {
      yield false;
      return;
    }

    print(
        '[Shared Notification Stream] Starting stream for user: $userEmail, token: ${fcmToken?.substring(0, 10)}...');

    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      print(
          '[Shared Notification Stream] Checking ${snapshot.docs.length} unread notifications');

      final hasMatchingNotification = snapshot.docs.any((doc) {
        final data = doc.data();
        final type = data['data']?['type'] ?? '';
        final tokenMatch = fcmToken != null && data['token'] == fcmToken;
        final emailMatch = userEmail != null &&
            (data['toEmail'] == userEmail ||
                data['data']?['toEmail'] == userEmail);
        final isMatching = (type == 'invitation' || type == 'comment') &&
            (tokenMatch || emailMatch);

        print(
            '[Shared Notification Stream] Doc ${doc.id}: type=$type, tokenMatch=$tokenMatch, emailMatch=$emailMatch, isMatching=$isMatching');

        return isMatching;
      });

      print(
          '[Shared Notification Stream] Has matching notifications: $hasMatchingNotification');
      return hasMatchingNotification;
    });
  }

  // Mark all collaboration notifications as read
  static Future<void> markAllCollabNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final userEmail = user.email;
    if (fcmToken == null && userEmail == null) return;

    print(
        '[Shared Notification Service] Marking all collab notifications as read for user: $userEmail');

    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    int markedCount = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['data']?['type'] ?? '';
      final tokenMatch = fcmToken != null && data['token'] == fcmToken;
      final emailMatch = userEmail != null &&
          (data['toEmail'] == userEmail ||
              data['data']?['toEmail'] == userEmail);
      if ((type == 'invitation' || type == 'comment') &&
          (tokenMatch || emailMatch)) {
        await doc.reference.update({'read': true});
        markedCount++;
        print(
            '[Shared Notification Service] Marked notification ${doc.id} as read');
      }
    }

    print(
        '[Shared Notification Service] Marked $markedCount notifications as read');
  }

  // Clean up orphaned notifications that don't belong to any current user
  static Future<void> cleanupOrphanedNotifications() async {
    try {
      print('[Cleanup] Starting orphaned notification cleanup...');

      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      print(
          '[Cleanup] Found ${snapshot.docs.length} unread notifications to check');

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final token = data['token'];
        final toEmail = data['toEmail'];
        final dataEmail = data['data']?['toEmail'];

        // Check if notification has valid recipient info
        if ((token == null || token.toString().isEmpty) &&
            (toEmail == null || toEmail.toString().isEmpty) &&
            (dataEmail == null || dataEmail.toString().isEmpty)) {
          print(
              '[Cleanup] Deleting orphaned notification ${doc.id} - no valid recipient');
          await doc.reference.delete();
          deletedCount++;
        }
      }

      print('[Cleanup] Deleted $deletedCount orphaned notifications');
    } catch (e) {
      print('[Cleanup] Error cleaning up notifications: $e');
    }
  }

  // Force clear all notifications for current user (for testing)
  static Future<void> clearAllNotificationsForCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      final userEmail = user.email;

      print(
          '[Clear All] Clearing notifications for user: $userEmail, token: ${fcmToken?.substring(0, 10)}...');

      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      int clearedCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tokenMatch = fcmToken != null && data['token'] == fcmToken;
        final emailMatch = userEmail != null &&
            (data['toEmail'] == userEmail ||
                data['data']?['toEmail'] == userEmail);

        if (tokenMatch || emailMatch) {
          await doc.reference.update({'read': true});
          clearedCount++;
          print('[Clear All] Marked notification ${doc.id} as read');
        }
      }

      print('[Clear All] Cleared $clearedCount notifications for current user');
    } catch (e) {
      print('[Clear All] Error clearing notifications: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      // Get the user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final String? fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        print('No FCM token found for user $userId');
        return;
      }

      // Send the notification using Cloud Functions
      await _firestore.collection('notifications').add({
        'token': fcmToken,
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
    required String todoName,
  }) async {
    await sendNotification(
      userId: inviterId,
      title: 'Einladung abgelehnt',
      body:
          '$inviteeName hat deine Einladung zur Zusammenarbeit an "$todoName" abgelehnt',
      data: {
        'type': 'invitation_rejected',
        'todoName': todoName,
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
}

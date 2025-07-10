// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Call once in main() before runApp()
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1️⃣ Initialize timezones
    tz.initializeTimeZones();

    // 2️⃣ Android-specific initialization
    const androidSettings = AndroidInitializationSettings('notificationicon');

    // 3️⃣ iOS-specific initialization
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4️⃣ Combine platform settings
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 5️⃣ Initialize plugin
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped payload: ${response.payload}');
      },
    );

    // 6️⃣ Create notification channel for Android
    await _createNotificationChannel();

    // 7️⃣ Request Android notification & exact-alarms permissions (Android 13+)
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final notifGranted = await androidImpl.areNotificationsEnabled();
      debugPrint('Android notification permission granted: $notifGranted');

      if (!notifGranted!) {
        await androidImpl.requestNotificationsPermission();
      }

      final alarmsGranted = await androidImpl.requestExactAlarmsPermission();
      debugPrint('Exact alarms permission granted: $alarmsGranted');
    }

    // 8️⃣ Request iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    debugPrint('🔔 NotificationService initialized');
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'wedding_schedule_channel', // id
      'Wedding Alarms', // name
      description: 'Alarm reminders for wedding events',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(channel);
      debugPrint('🔔 Notification channel created');
    }
  }

  /// Show a full-screen "alarm" notification immediately
  static Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    String payload = '',
  }) async {
    // Android: loud sound, vibration, fullScreenIntent
    var androidDetails = AndroidNotificationDetails(
      'wedding_schedule_channel', // channel id
      'Wedding Alarms', // channel name
      channelDescription: 'Alarm reminders for wedding events',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: false,
      autoCancel: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
    );

    // iOS: custom sound if bundled
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      // sound: 'alarm_sound.aiff',
      interruptionLevel: InterruptionLevel.critical,
    );

    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iOSDetails),
        payload: payload,
      );
      debugPrint('⏰ Alarm notification shown (id=$id)');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  /// Cancel a single notification by its id
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    debugPrint('❌ Canceled notification $id');
  }

  static Future<void> cancelAllScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> ids =
          prefs.getStringList('scheduled_notification_ids') ?? [];

      for (String id in ids) {
        await _plugin.cancel(int.parse(id));
        debugPrint('❌ Canceled notification $id');
      }

      await prefs.remove('scheduled_notification_ids');
      debugPrint('🗑️ All scheduled notifications canceled');
    } catch (e) {
      debugPrint('❌ Error canceling notifications: $e');
    }
  }

  static Future<void> scheduleAlarmNotification({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Convert DateTime to TZDateTime in the local timezone
      final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      // Check if the scheduled date is in the future
      if (scheduledDate.isBefore(now)) {
        debugPrint(
            "❌ Cannot schedule notification for past time: $scheduledDate");
        return;
      }

      // Schedule the notification
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'wedding_schedule_channel',
            'Wedding Alarms',
            channelDescription: 'Alarm reminders for wedding events',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            ongoing: false,
            autoCancel: true,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
            sound: 'alarm_sound.aiff',
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Store the scheduled notification ID
      final prefs = await SharedPreferences.getInstance();
      final List<String> ids =
          prefs.getStringList('scheduled_notification_ids') ?? [];
      if (!ids.contains(id.toString())) {
        ids.add(id.toString());
        await prefs.setStringList('scheduled_notification_ids', ids);
      }

      debugPrint('⏰ Scheduled alarm (id=$id) for $scheduledDate');
      // Test immediate notification to verify setup
      // if (DateTime.now().difference(dateTime).inMinutes.abs() < 1) {
      //   await showAlarmNotification(
      //     id: id + 10000, // Different ID for test
      //     title: 'Test: $title',
      //     body: 'This is a test notification - $body',
      //     payload: payload ?? '',
      //   );
      // }
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  /// Get all pending notifications (for debugging)
  static Future<void> getPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _plugin.pendingNotificationRequests();

      debugPrint('📋 Pending notifications: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
    }
  }
}

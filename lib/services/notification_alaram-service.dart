// lib/services/notification_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

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
      requestCriticalPermission: true, // For critical alerts
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
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
        _handleNotificationTap(response.payload);
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
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // Request critical alert permission
      );
      debugPrint('iOS notification permissions granted: $granted');
    }

    debugPrint('🔔 NotificationService initialized');

    // Test platform-specific features
    if (Platform.isIOS) {
      debugPrint('📱 iOS notification features enabled');
    } else if (Platform.isAndroid) {
      debugPrint('🤖 Android notification features enabled');
    }
  }

  /// Handles notification tap events
  static Future<void> _handleNotificationTap(String? payload) async {
    if (payload == null || payload.isEmpty) {
      debugPrint('🔔 Notification tapped but no payload provided');
      return;
    }

    debugPrint('🔔 Handling notification tap with payload: $payload');

    try {
      // Check if payload is a file path
      final file = File(payload);

      if (await file.exists()) {
        debugPrint('📄 File exists, attempting to open: ${file.path}');

        // Check if it's a PDF file
        if (payload.toLowerCase().endsWith('.pdf')) {
          await _openPdfFile(file.path);
        } else {
          // For other file types, try to open with default app
          await _openFileWithDefaultApp(file.path);
        }
      } else {
        debugPrint('❌ File does not exist: $payload');
        // If it's not a file path, treat it as a URL or other action
        await _handleOtherPayload(payload);
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// Opens a PDF file using the system's default PDF viewer
  static Future<void> _openPdfFile(String filePath) async {
    try {
      debugPrint('📄 Opening PDF file: $filePath');

      // Try different methods based on platform
      if (Platform.isAndroid) {
        await _openPdfFileAndroid(filePath);
      } else if (Platform.isIOS) {
        await _openPdfFileIOS(filePath);
      } else {
        await _openPdfFileGeneric(filePath);
      }
    } catch (e) {
      debugPrint('❌ Error opening PDF file: $e');
    }
  }

  /// Android-specific PDF opening
  static Future<void> _openPdfFileAndroid(String filePath) async {
    try {
      // Try Android intent first
      final androidIntent =
          'intent://view?file=$filePath#Intent;scheme=file;type=application/pdf;end';
      final intentUri = Uri.parse(androidIntent);

      if (await canLaunchUrl(intentUri)) {
        await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        debugPrint('✅ PDF opened with Android intent');
        return;
      }

      // Fallback to generic method
      await _openPdfFileGeneric(filePath);
    } catch (e) {
      debugPrint('❌ Android PDF opening failed: $e');
      await _openPdfFileGeneric(filePath);
    }
  }

  /// iOS-specific PDF opening
  static Future<void> _openPdfFileIOS(String filePath) async {
    try {
      // iOS handles file URIs well
      final uri = Uri.file(filePath);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ PDF opened on iOS');
        return;
      }

      // Fallback to generic method
      await _openPdfFileGeneric(filePath);
    } catch (e) {
      debugPrint('❌ iOS PDF opening failed: $e');
      await _openPdfFileGeneric(filePath);
    }
  }

  /// Generic PDF opening method
  static Future<void> _openPdfFileGeneric(String filePath) async {
    try {
      // Create file URI
      final uri = Uri.file(filePath);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ PDF file opened successfully');
      } else {
        debugPrint('❌ Cannot launch PDF file');
        // Fallback: try with file:// scheme
        final fileUri = Uri.parse('file://$filePath');
        if (await canLaunchUrl(fileUri)) {
          await launchUrl(fileUri, mode: LaunchMode.externalApplication);
          debugPrint('✅ PDF file opened with file:// scheme');
        } else {
          debugPrint('❌ All PDF opening methods failed');
        }
      }
    } catch (e) {
      debugPrint('❌ Generic PDF opening failed: $e');
    }
  }

  /// Opens a file with the system's default app
  static Future<void> _openFileWithDefaultApp(String filePath) async {
    try {
      debugPrint('📁 Opening file with default app: $filePath');

      final uri = Uri.file(filePath);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ File opened successfully');
      } else {
        debugPrint('❌ Cannot launch file');
      }
    } catch (e) {
      debugPrint('❌ Error opening file: $e');
    }
  }

  /// Handles other types of payloads (URLs, custom actions, etc.)
  static Future<void> _handleOtherPayload(String payload) async {
    try {
      debugPrint('🔗 Handling other payload type: $payload');

      // Check if it's a URL
      if (payload.startsWith('http://') || payload.startsWith('https://')) {
        final uri = Uri.parse(payload);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          debugPrint('✅ URL opened successfully');
        }
      } else {
        debugPrint('ℹ️ Unknown payload type, no action taken');
      }
    } catch (e) {
      debugPrint('❌ Error handling other payload: $e');
    }
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

    // iOS: enhanced notification details
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      sound: 'default', // Use default iOS sound
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'wedding_reminder',
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
        debugPrint("   Current time: $now");
        debugPrint("   Requested time: $scheduledDate");
        debugPrint(
            "   Difference: ${scheduledDate.difference(now).inMinutes} minutes");
        return;
      }

      debugPrint("✅ Scheduling notification for future time: $scheduledDate");
      debugPrint("   Current time: $now");
      debugPrint(
          "   Time until notification: ${scheduledDate.difference(now).inMinutes} minutes");

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
            sound: 'default', // Use default iOS sound for reliability
            interruptionLevel: InterruptionLevel.critical,
            categoryIdentifier: 'wedding_reminder',
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

  /// Test immediate notification
  static Future<void> testNotification() async {
    debugPrint('🧪 Testing immediate notification...');
    await showAlarmNotification(
      id: 999,
      title: '🧪 Test Notification',
      body: 'If you see this, notifications are working!',
      payload: 'test_payload',
    );
    debugPrint('✅ Test notification sent');
  }

  /// Test scheduled notification (5 seconds from now)
  static Future<void> testScheduledNotification() async {
    final testTime = DateTime.now().add(Duration(seconds: 5));
    debugPrint('🧪 Testing scheduled notification for: $testTime');

    await scheduleAlarmNotification(
      id: 998,
      dateTime: testTime,
      title: '🧪 Scheduled Test',
      body: 'This scheduled notification should appear in 5 seconds!',
      payload: 'scheduled_test_payload',
    );

    debugPrint('✅ Scheduled test notification');
  }

  /// Check and request all necessary permissions
  static Future<bool> checkAndRequestPermissions() async {
    bool allPermissionsGranted = true;

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // Check notification permissions
        final notificationsEnabled =
            await androidImpl.areNotificationsEnabled();
        debugPrint('🔍 Notifications enabled: $notificationsEnabled');

        if (notificationsEnabled == false) {
          debugPrint('❌ Requesting notification permission...');
          final granted = await androidImpl.requestNotificationsPermission();
          debugPrint('🔍 Notification permission granted: $granted');
          allPermissionsGranted = allPermissionsGranted && (granted ?? false);
        }

        // Check exact alarm permissions
        final exactAlarmPermission =
            await androidImpl.canScheduleExactNotifications();
        debugPrint('🔍 Exact alarm permission: $exactAlarmPermission');

        if (exactAlarmPermission == false) {
          debugPrint('❌ Requesting exact alarm permission...');
          final granted = await androidImpl.requestExactAlarmsPermission();
          debugPrint('🔍 Exact alarm permission granted: $granted');
          allPermissionsGranted = allPermissionsGranted && (granted ?? false);
        }
      }
    }

    debugPrint('🔍 All permissions granted: $allPermissionsGranted');
    return allPermissionsGranted;
  }
}

// Add this debug helper to your app to test notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';

class NotificationDebugHelper {
  
  /// Test immediate notification
  static Future<void> testImmediateNotification() async {
    print('🧪 Testing immediate notification...');
    await NotificationService.showAlarmNotification(
      id: 999,
      title: '🧪 Test Notification',
      body: 'If you see this, notifications are working!',
      payload: 'test_payload',
    );
  }

  /// Test scheduled notification (5 seconds from now)
  static Future<void> testScheduledNotification() async {
    final testTime = DateTime.now().add(Duration(seconds: 5));
    print('🧪 Testing scheduled notification for: $testTime');
    
    await NotificationService.scheduleAlarmNotification(
      id: 998,
      dateTime: testTime,
      title: '🧪 Scheduled Test',
      body: 'This scheduled notification should appear in 5 seconds!',
      payload: 'scheduled_test_payload',
    );
    
    print('✅ Scheduled test notification');
  }

  /// Check notification permissions
  static Future<void> checkPermissions() async {
    final androidImpl = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      final notificationsEnabled = await androidImpl.areNotificationsEnabled();
      final exactAlarmPermission = await androidImpl.canScheduleExactNotifications();
      
      print('🔍 Notification Permissions Check:');
      print('  - Notifications enabled: $notificationsEnabled');
      print('  - Exact alarm permission: $exactAlarmPermission');
      
      if (!notificationsEnabled!) {
        print('❌ Notifications are disabled - requesting permission...');
        await androidImpl.requestNotificationsPermission();
      }
      
      if (!exactAlarmPermission!) {
        print('❌ Exact alarm permission missing - requesting...');
        await androidImpl.requestExactAlarmsPermission();
      }
    }
  }

  /// Show all pending notifications
  static Future<void> showPendingNotifications() async {
    await NotificationService.getPendingNotifications();
  }

  /// Complete notification test suite
  static Future<void> runFullTest() async {
    print('🚀 Starting full notification test suite...\n');
    
    // 1. Check permissions
    await checkPermissions();
    await Future.delayed(Duration(seconds: 1));
    
    // 2. Test immediate notification
    await testImmediateNotification();
    await Future.delayed(Duration(seconds: 2));
    
    // 3. Test scheduled notification
    await testScheduledNotification();
    await Future.delayed(Duration(seconds: 1));
    
    // 4. Show pending notifications
    await showPendingNotifications();
    
    print('\n✅ Full notification test completed!');
    print('📝 Check your device for:');
    print('  1. Immediate test notification');
    print('  2. Scheduled notification (in ~5 seconds)');
  }
}



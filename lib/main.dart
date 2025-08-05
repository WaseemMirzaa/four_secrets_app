import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/firebase_options.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';
import 'package:four_secrets_wedding_app/services/push_notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;

// This must be a top‐level or @pragma('vm:entry-point') function
@pragma('vm:entry-point')
void alarmCallback(int id) {
  // When AlarmManager fires, show the notification
  NotificationService.showAlarmNotification(
    id: id,
    title: '🔔 Wedding Reminder',
    body: 'Time for your event!',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data for alarm functionality
  tz.initializeTimeZones();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );

    print('🔥 Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Firebase: $e');
  }

  // Initialize Hive for local data storage
  try {
    await Hive.initFlutter();
    await Hive.openBox('myboxToDo');
    await Hive.openBox('myboxGuest');

    print('💾 Hive initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Hive: $e');
  }

  // Request location permission before running the app, but do not show dialog if denied
  try {
    await Permission.location.request();
    print('📍 Location permission requested');
  } catch (e) {
    debugPrint('❌ Failed to request location permission: $e');
  }

  // Initialize NotificationService
  try {
    await NotificationService.initialize();
    print('🔔 NotificationService initialized successfully');
  } catch (e) {
    print('❌ NotificationService initialization failed: $e');
  }

  // Initialize PushNotificationService
  try {
    final pushNotificationService = PushNotificationService();
    await pushNotificationService.initialize();

    // Get and save FCM token
    await pushNotificationService.getFcmTokenAndSaveToFirestore();

    print('🔔 PushNotificationService initialized successfully');
  } catch (e) {
    print('❌ PushNotificationService initialization failed: $e');
  }

  // Get FCM token in background to avoid blocking UI
  Future.microtask(() async {
    try {
      final testToken = await PushNotificationService().getFcmTokenDirect();
      if (testToken != null) {
        print('🟢 Test FCM token successful');
      } else {
        print('🟡 Test FCM token returned null');
      }
    } catch (e) {
      print('❌ FCM token test failed: $e');
    }
  });

  // Set preferred orientations
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    print('📱 Device orientation set to portrait');
  } catch (e) {
    debugPrint('❌ Failed to set device orientation: $e');
  }

  runApp(
    MaterialApp(
      title: '4secrets - Wedding Planner',
      theme: ThemeData(
        textTheme: GoogleFonts.openSansTextTheme(),
      ),
      initialRoute: RouteManager.splashScreen,
      onGenerateRoute: RouteManager.generateRoute,
      debugShowCheckedModeBanner: false,
    ),
  );
}

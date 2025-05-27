import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:four_secrets_wedding_app/firebase_options.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/services/notification_alaram-service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  tz.initializeTimeZones();
 
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode 
        ? AndroidProvider.debug 
        : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttest,
    );
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }

  // 3️⃣ Initialize NotificationService
  try {
    await NotificationService.initialize();
    print('🔔 NotificationService initialized successfully');
  } catch (e) {
    print('❌ NotificationService initialization failed: $e');
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // init Hive
  await Hive.initFlutter();
  // Only keep the guest box, remove the todo box
  await Hive.openBox('myboxGuest');

  runApp(
    MaterialApp(
      title: '4 Secrets Wedding Planer',
      theme: ThemeData(
        textTheme: GoogleFonts.openSansTextTheme(),
      ),
      initialRoute: RouteManager.splashScreen,
      onGenerateRoute: RouteManager.generateRoute,
      debugShowCheckedModeBanner: false,
    ),
  );
}

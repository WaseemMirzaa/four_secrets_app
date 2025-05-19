import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:four_secrets_wedding_app/firebase_options.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

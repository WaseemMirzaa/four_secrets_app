import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class UrlEmailInstagram {
  // Method for connection with i. e. HomePage
  static void getLaunchHomepage({
    required String url,
    required String modeString,
  }) async {
    final finalUrl = Uri.parse(url);

    try {
      if (await canLaunchUrl(finalUrl)) {}
      await launchUrl(
        finalUrl,
        mode: helperLaunchMode(modeString),
      ); // Show in Browser
    } catch (e) {
      print("$e" + ", " + "Cannot launch to: $url ( 404 not found )");
    }
  }

  // Method for sending E-Mails with debug info
  // Method for sending E-Mails with comprehensive fallback strategy for mobile
  static Future<void> sendEmail({
    required String toEmail,
    String subject = "",
    String body = "",
  }) async {
    try {
      print("Original email: $toEmail");

      // Clean email address
      final cleanEmail = toEmail.trim();

      // Create the mailto URI
      final emailUri = Uri(
        scheme: 'mailto',
        path: cleanEmail,
        queryParameters: {
          if (subject.isNotEmpty) 'subject': subject,
          if (body.isNotEmpty) 'body': body,
        },
      );

      print("Formatted URI: ${emailUri.toString()}");

      // **CRITICAL FIX: Try direct launch first (some Android devices have issues with canLaunchUrl)**
      try {
        print("Attempting direct launch...");
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        print("Direct launch successful");
        return;
      } catch (e) {
        print("Direct launch failed: $e");
      }

      // If direct launch failed, try with canLaunchUrl check
      final canLaunch = await canLaunchUrl(emailUri);
      print("Can launch URL: $canLaunch");

      if (canLaunch) {
        // Try different launch modes in order
        final launchModes = [
          LaunchMode.externalApplication, // Most reliable for email
          LaunchMode.platformDefault,
        ];

        for (final mode in launchModes) {
          try {
            await launchUrl(emailUri, mode: mode);
            print("Launched successfully with mode: $mode");
            return;
          } catch (e) {
            print("Failed with mode $mode: $e");
            continue; // Try next mode
          }
        }
      }

      // **STRATEGY 2: Try without query parameters (simpler URI)**
      try {
        final simpleUri = Uri(scheme: 'mailto', path: cleanEmail);
        print("Trying simple URI: $simpleUri");

        final canLaunchSimple = await canLaunchUrl(simpleUri);
        if (canLaunchSimple) {
          await launchUrl(simpleUri, mode: LaunchMode.externalApplication);
          print("Launched simple mailto URI");
          return;
        }
      } catch (e) {
        print("Simple URI failed: $e");
      }

      // **STRATEGY 3: Platform-specific fallbacks**

      // For Android devices
      if (Platform.isAndroid) {
        print("Trying Android-specific fallbacks...");

        // Option A: Try Gmail app/web
        try {
          final gmailUri = Uri.parse(
            'https://mail.google.com/mail/?view=cm&fs=1&to=$cleanEmail'
            '&su=${Uri.encodeComponent(subject)}'
            '&body=${Uri.encodeComponent(body)}',
          );

          if (await canLaunchUrl(gmailUri)) {
            await launchUrl(gmailUri);
            print("Opened in Gmail app/web");
            return;
          }
        } catch (e) {
          print("Gmail fallback failed: $e");
        }

        // Option B: Try opening email apps via package names (Android intents)
        try {
          // Try common email apps
          final emailApps = [
            'com.google.android.gm', // Gmail
            'com.android.email', // Android Email
            'com.samsung.android.email.provider', // Samsung Email
            'com.microsoft.office.outlook', // Outlook
            'com.yahoo.mobile.client.android.mail', // Yahoo Mail
          ];

          for (final package in emailApps) {
            try {
              final intentUri = Uri.parse(
                'intent://send?to=$cleanEmail#Intent;package=$package;end',
              );
              if (await canLaunchUrl(intentUri)) {
                await launchUrl(intentUri);
                print("Opened in $package");
                return;
              }
            } catch (e) {
              // Continue to next app
            }
          }
        } catch (e) {
          print("Package-specific intents failed: $e");
        }
      }

      // For iOS devices
      if (Platform.isIOS) {
        print("Trying iOS-specific fallbacks...");

        // iOS has good mailto support, but let's try Apple Mail specifically
        try {
          // Try opening mail settings or create new email
          final mailUri = Uri.parse('message://');
          if (await canLaunchUrl(mailUri)) {
            await launchUrl(mailUri);
            return;
          }
        } catch (e) {
          print("iOS mail fallback failed: $e");
        }

        // Try the default mail app via URL scheme
        try {
          final defaultMailUri = Uri.parse('mailto:$cleanEmail');
          if (await canLaunchUrl(defaultMailUri)) {
            await launchUrl(defaultMailUri);
            return;
          }
        } catch (e) {
          print("Default mailto on iOS failed: $e");
        }
      }

      // **STRATEGY 4: If all else fails, open browser with webmail**
      print("All native methods failed, trying webmail...");
      try {
        final webmailUri = Uri.parse(
          'https://mail.google.com/mail/?view=cm&to=$cleanEmail'
          '&su=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
        );

        if (await canLaunchUrl(webmailUri)) {
          await launchUrl(webmailUri);
          print("Opened in browser with webmail");
          return;
        }
      } catch (e) {
        print("Webmail fallback also failed: $e");
      }

      // **FINAL FALLBACK: Throw exception to be handled by UI**
      throw Exception(
        'No email app found. '
        'Please install an email app or use webmail at https://mail.google.com',
      );
    } catch (e) {
      print("Email launch completely failed: $e");
      rethrow; // Let the UI handle this
    }
  }

  static void getlaunchInstagram({
    required String url,
    required String modeString,
  }) async {
    final finalUrl = Uri.parse(url);

    try {
      if (await canLaunchUrl(finalUrl)) {}
      await launchUrl(finalUrl, mode: helperLaunchMode(modeString));
    } catch (e) {
      print("$e" + ", " + "Cannot launch to: $url ( 404 not found )");
    }
  }

  // Dial Phonenumber
  static void openDialPad(String phoneNumber) async {
    Uri url = Uri(scheme: "tel", path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print("Can't open dial pad.");
    }
  }

  static LaunchMode helperLaunchMode(String modeString) {
    var mode = LaunchMode.platformDefault;
    switch (modeString) {
      case "default":
        mode = LaunchMode.platformDefault;
        break;
      case "appWeb":
        mode = LaunchMode.inAppWebView;
        break;
      case "external":
        mode = LaunchMode.externalApplication;
        break;
      case "appBrowser":
        mode = LaunchMode.inAppBrowserView;
        break;
      default:
        mode = LaunchMode.platformDefault;
        break;
    }
    return mode;
  }
}

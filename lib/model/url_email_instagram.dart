import 'package:url_launcher/url_launcher.dart';

class UrlEmailInstagram {
// Method for connection with i. e. HomePage
  static void getLaunchHomepage(
      {required String url, required String modeString}) async {
    final finalUrl = Uri.parse(url);

    try {
      if (await canLaunchUrl(finalUrl)) {}
      await launchUrl(finalUrl,
          mode: helperLaunchMode(modeString)); // Show in Browser
    } catch (e) {
      print("$e" + ", " + "Cannot launch to: $url ( 404 not found )");
    }
  }

  // Method for sending E-Mails
  static void sendEmail(
      {required String toEmail, String subject = "", String body = ""}) async {
    final emailUri = Uri.parse(
        'mailto:$toEmail?subject=${Uri.encodeFull(subject)}&body=${Uri.encodeFull(body)}');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        print("Keine E-Mail-App gefunden");
      }
    } catch (e) {
      print("Fehler beim Öffnen der E-Mail-App: $e");
    }
  }

  // Method for connection with Instagram
  static void getlaunchInstagram(
      {required String url, required String modeString}) async {
    final finalUrl = Uri.parse(url);

    try {
      if (await canLaunchUrl(finalUrl)) {}
      await launchUrl(finalUrl,
          mode: helperLaunchMode(modeString)); // Show in Browser
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

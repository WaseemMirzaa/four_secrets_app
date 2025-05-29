import UIKit
import Flutter
// import FirebaseCore
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Firebase setup (uncomment if needed)
    // FirebaseApp.configure()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

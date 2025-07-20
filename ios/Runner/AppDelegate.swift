import UIKit
import Flutter
import UserNotifications
import GoogleMaps
// import FirebaseCore
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDR_QZaW3xiJfLLNFybEd6e6HunqDkUjJg")
    GeneratedPluginRegistrant.register(with: self)

    // Configure notification center
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      // Configure notification categories
      self.configureNotificationCategories()

      // Request notification permissions
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if let error = error {
            print("❌ Notification permission error: \(error)")
          } else {
            print("🔔 Notification permission granted: \(granted)")
          }
        }
      )
    }

    // Firebase setup (uncomment if needed)
    // FirebaseApp.configure()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle notification when app is in foreground
  @available(iOS 10.0, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show notification even when app is in foreground
    completionHandler([.alert, .badge, .sound])
  }

  // Handle notification tap
  @available(iOS 10.0, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
    // Handle notification tap
    let userInfo = response.notification.request.content.userInfo
    print("🔔 Notification tapped with payload: \(userInfo)")

    // You can add custom handling here if needed
    // For example, navigate to specific screen based on payload

    completionHandler()
  }

  // Configure notification categories for better handling
  @available(iOS 10.0, *)
  private func configureNotificationCategories() {
    // Define actions for wedding reminder notifications
    let viewAction = UNNotificationAction(
      identifier: "VIEW_ACTION",
      title: "View Details",
      options: [.foreground]
    )

    let dismissAction = UNNotificationAction(
      identifier: "DISMISS_ACTION",
      title: "Dismiss",
      options: []
    )

    // Create category for wedding reminders
    let weddingCategory = UNNotificationCategory(
      identifier: "wedding_reminder",
      actions: [viewAction, dismissAction],
      intentIdentifiers: [],
      options: [.customDismissAction]
    )

    // Register categories
    UNUserNotificationCenter.current().setNotificationCategories([weddingCategory])
    print("🔔 Notification categories configured")
  }
}

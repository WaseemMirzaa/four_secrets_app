import UIKit
import Flutter
import UserNotifications
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()

    // Configure Google Maps
    GMSServices.provideAPIKey("AIzaSyDR_QZaW3xiJfLLNFybEd6e6HunqDkUjJg")

    // Configure FCM
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self

    // Request notification permissions
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      print("FCM iOS: Notification permission granted: \(granted)")
      if let error = error {
        print("FCM iOS: Notification permission error: \(error)")
      }
    }

    // Register for remote notifications
    application.registerForRemoteNotifications()

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

  // MARK: - FCM Delegate Methods
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM iOS: Registration token received: \(fcmToken ?? "nil")")

    // Send token to Flutter
    if let token = fcmToken {
      let userInfo = ["token": token]
      NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: userInfo)
    }
  }

  // Handle notification when app is in foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("FCM iOS: Foreground notification received")

    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // Handle notification tap
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
    print("FCM iOS: Notification tapped")

    let userInfo = response.notification.request.content.userInfo
    print("FCM iOS: Notification data: \(userInfo)")

    completionHandler()
  }

  // Handle APNs registration
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("FCM iOS: APNs token received")
    Messaging.messaging().apnsToken = deviceToken
  }

  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("FCM iOS: Failed to register for remote notifications: \(error)")
  }
}

# iOS Local Notifications Setup Guide

## 📱 **iOS Configuration for Wedding App Notifications**

### 🎯 **Overview**
This guide covers the iOS-specific setup required for local notifications in the Four Secrets Wedding App, including both the original Tagesablauf and the new Eigene Dienstleister features.

### 🔧 **Xcode Project Configuration**

#### 1. **Add Entitlements File to Xcode**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on `Runner` project in navigator
3. Select "Add Files to Runner"
4. Navigate to `ios/Runner/Runner.entitlements`
5. Add the file to the project
6. In project settings → Build Settings → Code Signing Entitlements
7. Set the path to: `Runner/Runner.entitlements`

#### 2. **Configure Notification Capabilities**
1. In Xcode, select the `Runner` project
2. Go to "Signing & Capabilities" tab
3. Click "+" to add capabilities:
   - **Push Notifications**
   - **Background Modes** (select "Background processing" and "Remote notifications")
   - **Critical Alerts** (if available in your Apple Developer account)

#### 3. **Add Custom Notification Sound (Optional)**
1. Create or obtain an `.aiff` audio file (max 30 seconds)
2. Name it `alarm_sound.aiff`
3. Add it to `ios/Runner/` directory
4. In Xcode, add the file to the Runner target
5. Ensure it's included in "Copy Bundle Resources" build phase

### 📋 **Required Permissions in Info.plist**
The following permissions are already configured:

```xml
<key>NSUserNotificationUsageDescription</key>
<string>This app uses notifications to remind you of important events.</string>
<key>NSUserNotificationsUsageDescription</key>
<string>This app uses notifications to remind you of important wedding events and appointments.</string>
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>remote-notification</string>
</array>
```

### 🔔 **Notification Features Implemented**

#### **Critical Alerts**
- High-priority notifications that bypass Do Not Disturb
- Requires special entitlement from Apple
- Used for important wedding reminders

#### **Background Processing**
- Allows notifications to be scheduled even when app is closed
- Ensures reminders are delivered on time

#### **Notification Categories**
- Custom actions: "View Details" and "Dismiss"
- Better user interaction with notifications

### 🎵 **Sound Configuration**

#### **Default Sound (Current)**
- Uses iOS default notification sound
- Reliable and always available
- No additional setup required

#### **Custom Sound (Optional)**
To use a custom alarm sound:
1. Replace `'default'` with `'alarm_sound.aiff'` in notification service
2. Add the actual sound file to iOS project
3. Ensure file is in AIFF format, under 30 seconds

### 🚀 **Testing Notifications**

#### **Device Testing**
1. Run app on physical iOS device (notifications don't work in simulator)
2. Grant notification permissions when prompted
3. Create a reminder with future date/time
4. Lock device and wait for notification

#### **Permission Verification**
Check iOS Settings → [App Name] → Notifications to verify:
- Allow Notifications: ON
- Critical Alerts: ON (if available)
- Sounds: ON
- Badges: ON

### 🔍 **Troubleshooting**

#### **Notifications Not Appearing**
1. Check device notification settings
2. Verify app has notification permissions
3. Ensure reminder time is in the future
4. Check device Do Not Disturb settings

#### **Critical Alerts Not Working**
1. Verify entitlements file is properly added to Xcode
2. Check Apple Developer account for critical alerts capability
3. Ensure proper code signing

#### **Custom Sound Not Playing**
1. Verify sound file is in AIFF format
2. Check file is added to Xcode project
3. Ensure file is included in app bundle
4. File size should be under 30 seconds

### 📱 **iOS Version Compatibility**
- **iOS 10.0+**: Full notification support
- **iOS 12.0+**: Critical alerts support
- **iOS 15.0+**: Enhanced notification features

### 🔐 **Apple Developer Requirements**
- **Standard Notifications**: No special approval needed
- **Critical Alerts**: Requires approval from Apple
- **Background Processing**: Standard capability

### 📝 **Implementation Status**
✅ Basic local notifications
✅ Permission handling
✅ Background scheduling
✅ Notification categories
✅ Critical alert support
✅ Default sound implementation
⚠️ Custom sound (requires manual sound file addition)

### 🎯 **Next Steps**
1. Test on physical iOS device
2. Add custom sound file if desired
3. Submit for App Store review
4. Request critical alerts approval if needed

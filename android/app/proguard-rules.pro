# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Gson rules
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes
-keep class com.app.four_secrets_wedding_app.** { *; }

# General Android rules
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Window extensions rules
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**
-keep class androidx.window.extensions.** { *; }
-keep class androidx.window.sidecar.** { *; }

# Play Core rules
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Core app compat rules
-dontwarn androidx.core.app.OnUserLeaveHintProvider
-keep class androidx.core.app.OnUserLeaveHintProvider { *; }

# Suppress warnings
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*
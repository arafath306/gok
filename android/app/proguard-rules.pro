# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class org.chromium.** { *; }

# Keep code that might be invoked via reflection / method channels
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * extends io.flutter.plugin.common.EventChannel$StreamHandler { *; }

# Ignore missing Play Store Split/Deferred component classes in Flutter
-dontwarn com.google.android.play.core.**

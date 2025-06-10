# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Sensor plugin rules
-keep class io.flutter.plugins.sensors.** { *; }

# Geolocator plugin rules
-keep class com.baseflow.geolocator.** { *; }

# URL launcher plugin rules
-keep class io.flutter.plugins.urllauncher.** { *; }

# Local notifications plugin rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Shared preferences plugin rules
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# SQLite plugin rules
-keep class com.tekartik.sqflite.** { *; }

# HTTP plugin rules
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }

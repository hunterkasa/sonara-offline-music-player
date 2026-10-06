# ProGuard and R8 Optimization Rules for Sonara

# Flutter Wrapper and Engine Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Audio Service & Foreground Playback Engine
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }

# SQLite Native C Libs and WAL Mode
-keep class org.sqlite.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keep class io.simform.sqlite3.** { *; }

# Sonara App Widgets & Receivers
-keep class com.example.sonara.sonara.** { *; }
-keepattributes *Annotation*

# Flutter Deferred Components / Play Core (unused in offline standalone Sonara)
-dontwarn com.google.android.play.core.**


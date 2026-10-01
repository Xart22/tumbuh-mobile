# Flutter engine + embedding.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Plugins that rely on reflection / JNI entry points.
-keep class io.flutter.plugins.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.biometric.** { *; }

# Keep annotations used by Drift/sqlite3 native bindings.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

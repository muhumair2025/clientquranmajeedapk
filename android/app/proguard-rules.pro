# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Media player related classes
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }

# Audio players plugin
-keep class xyz.luan.audioplayers.** { *; }

# Video player plugin
-keep class io.flutter.plugins.videoplayer.** { *; }

# Chewie video player
-keep class com.github.flutter_chewie.** { *; }

# Dio HTTP client
-keep class com.diox.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Network and connectivity
-keep class android.net.** { *; }
-keep class java.net.** { *; }

# Prevent obfuscation of media-related native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep all classes that might be referenced by reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses 
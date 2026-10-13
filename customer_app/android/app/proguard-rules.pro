# R8 Code & Resource Shrinking rules for District Car / Pashuraksha
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Flutter and AndroidX
-keep class io.flutter.** { *; }
-keep class androidx.activity.** { *; }

# Google Play Services & Firebase
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Safe image decoding (prevents R8 aggressive stripping)
-keepclassmembers class * {
    android.graphics.BitmapFactory$Options *;
}

# Keep Flutter Map and networking classes
-keep class com.mapbox.** { *; }
-keep class org.osmdroid.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Keep Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep SQLite
-keep class com.tekartik.sqflite.** { *; }

# Keep Geocoding
-keep class com.baseflow.geocoding.** { *; }

# Keep networking for map tiles
-keep class java.net.** { *; }
-keep class javax.net.ssl.** { *; }
-keep class android.net.** { *; }

# Don't warn about missing classes
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn com.mapbox.**
# ── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Porcupine / Picovoice ────────────────────────────────────────────────────
# Keep all Picovoice JNI bridge classes so R8 doesn't strip them in release.
-keep class ai.picovoice.** { *; }
-keepclassmembers class ai.picovoice.** { *; }
-dontwarn ai.picovoice.**

# ── record (audio recorder) ──────────────────────────────────────────────────
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# ── permission_handler ───────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ── General JNI / native ─────────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

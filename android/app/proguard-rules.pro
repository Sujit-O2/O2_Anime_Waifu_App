# ── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── ONNX Runtime ─────────────────────────────────────────────────────────────
# Keep ONNX Runtime JNI bridge classes so R8 doesn't strip them in release.
-keep class ai.onnxruntime.** { *; }
-keepclassmembers class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

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

# ── Firebase ──────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ── Gson (used by many plugins) ───────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# ── mobile_scanner / barcode ──────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ── Kotlin coroutines ─────────────────────────────────────────────────────────
-dontwarn kotlinx.coroutines.**

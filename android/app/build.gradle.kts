plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.anime_waifu"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Desugaring support for Java APIs on older Android versions
        isCoreLibraryDesugaringEnabled = true
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module",
            )
        }
        // Prevent duplicate native lib conflicts from ONNX/Firebase/etc
        jniLibs {
            // false = AGP streams .so from APK at runtime (minSdk 24+ safe)
            // avoids decompressing all native libs into heap during packaging
            useLegacyPackaging = false
            pickFirsts += setOf(
                "lib/x86/libc++_shared.so",
                "lib/x86_64/libc++_shared.so",
                "lib/armeabi-v7a/libc++_shared.so",
                "lib/arm64-v8a/libc++_shared.so",
            )
        }
    }

    defaultConfig {
        applicationId = "com.example.anime_waifu"
        minSdkVersion(24)  // Required by flutter_inappwebview (WebView APIs)
        targetSdkVersion(35)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Only ship arm64-v8a — covers 99%+ of modern Android devices.
        // Drops x86_64 (emulators) and armeabi-v7a (32-bit, pre-2016 phones).
        // This alone cuts native lib size by ~2/3 (~70MB saved).
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    buildTypes {
        debug {
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Temporarily disabled due to memory constraints
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                debugSymbolLevel = "NONE"
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("pl.droidsonroids.gif:android-gif-drawable:1.2.29")
    implementation("androidx.cardview:cardview:1.0.0")
    // ONNX Runtime for on-device Whisper STT + Sentiment Analysis
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.20.0")
    // Gson for JSON parsing theme colors
    implementation("com.google.code.gson:gson:2.11.0")
}

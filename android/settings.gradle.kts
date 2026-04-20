pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.android.settings") version "8.11.1"
}

android {
    execution {
        profiles {
            create("r8-high-memory") {
                r8 {
                    runInSeparateProcess = true
                    jvmOptions += listOf("-Xms2G", "-Xmx8G", "-XX:+UseG1GC", "-XX:G1HeapRegionSize=16m")
                }
            }
        }
        defaultProfile = "r8-high-memory"
    }
}

include(":app")

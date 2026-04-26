allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Suppress Java 8 obsolete warnings from dependencies
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        // Keep plugin builds compatible with common Android JDK setups.
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                val javaVersion17 = org.gradle.api.JavaVersion.VERSION_17
                compileOptions.javaClass.getMethod("setSourceCompatibility", org.gradle.api.JavaVersion::class.java).invoke(compileOptions, javaVersion17)
                compileOptions.javaClass.getMethod("setTargetCompatibility", org.gradle.api.JavaVersion::class.java).invoke(compileOptions, javaVersion17)
            } catch (e: Exception) {
            }
        }

        // Disable lint task file locks on Windows that fatally interrupt Flutter plugin builds
        tasks.configureEach {
            if (name.contains("lintVitalAnalyzeRelease") || name.contains("lint")) {
                enabled = false
            }
        }

        tasks.withType<JavaCompile> {
            options.compilerArgs.add("-Xlint:-options")
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }

        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }

        // Auto-set namespace from AndroidManifest for plugins that don't declare it
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                val namespaceMethod = android.javaClass.getMethod("getNamespace")
                val ns = namespaceMethod.invoke(android)
                if (ns == null || ns.toString().isEmpty()) {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val match = "package=\"([a-zA-Z0-9_\\\\.]+)\"".toRegex().find(content)
                        if (match != null) {
                            val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                            setNamespaceMethod.invoke(android, match.groupValues[1])
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore if method not found (e.g., older AGP)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Removed redundant Java enforcement block as it's now handled in the main afterEvaluate block above.

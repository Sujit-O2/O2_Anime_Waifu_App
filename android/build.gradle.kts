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
    
    // Ensure all subprojects use Java 17
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
    }

    afterEvaluate {
        val plugin = project
        if (plugin.hasProperty("android")) {
            val android = plugin.extensions.getByName("android")
            // BaseExtension doesn't exist directly nicely in this classpath without imports, 
            // but we can use reflection or cast. 
            // In Groovy we can just do android.namespace =, in Kotlin we need to reflect.
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

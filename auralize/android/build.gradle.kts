allprojects {
    repositories {
        google()
        mavenCentral()
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
}

subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android") ?: return@afterEvaluate
        runCatching {
            val getNamespace = androidExtension.javaClass.getMethod("getNamespace")
            val namespace = getNamespace.invoke(androidExtension) as? String
            if (namespace.isNullOrBlank()) {
                val setNamespace = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                val fallbackNamespace =
                    if (name == "flutter_media_metadata") "com.example.flutter_media_metadata"
                    else "com.$name.plugin"
                setNamespace.invoke(androidExtension, fallbackNamespace)
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

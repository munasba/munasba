allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some Flutter plugins (e.g. "printing") ship their own android/build.gradle
// with an older fallback compileSdkVersion (as low as 30). Because the app
// itself compiles against compileSdk 36, AAPT fails while linking merged
// resources that use attrs only present from API 31+ (e.g. android:attr/lStar),
// since those plugin modules are still being compiled against SDK 30.
// Force every plugin sub-module onto the same compileSdk as the app so
// resource linking is consistent across the whole build.
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.application") ||
            project.plugins.hasPlugin("com.android.library")
        ) {
            project.extensions.configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

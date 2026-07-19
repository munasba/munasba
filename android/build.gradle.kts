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
//
// NOTE: this must NOT touch the ":app" project — the block above already
// forces ":app" to evaluate early via evaluationDependsOn(":app"), so calling
// afterEvaluate on ":app" here throws:
//   "Cannot run Project.afterEvaluate(Action) when the project is already evaluated."
//
// We use afterEvaluate (not plugins.withId) because plugins.withId fires as
// soon as `apply plugin: 'com.android.library'` runs — which is near the top
// of each plugin's own build.gradle — so a plugin's own later
// `android { compileSdkVersion 30 }` line would silently overwrite our value
// right back down. afterEvaluate runs after the whole module script
// (including that line) has finished, so our override wins.
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            if (plugins.hasPlugin("com.android.library")) {
                extensions.configure<com.android.build.gradle.LibraryExtension> {
                    compileSdk = 36
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

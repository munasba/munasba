plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dawakti.app"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // NOTE: change this to your own reverse-domain application id before
        // publishing to the Play Store — "com.dawakti.app" is a placeholder.
        applicationId = "com.dawakti.app"
        minSdk = 23 // local_auth / flutter_secure_storage need >= 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: add your own release signing config before publishing.
            // Signing with the debug keys for now so `flutter build apk`
            // and cloud CI builds (Codemagic/FlutLab) succeed out of the box.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required because compileOptions.isCoreLibraryDesugaringEnabled = true above
    // (needed by flutter_local_notifications / timezone on minSdk < 26).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}

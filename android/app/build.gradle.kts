plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.carpooling"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildToolsVersion = "36.1.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.carpooling"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("../my-release-key.jks")
            storePassword = "mlekolaki"
            keyAlias = "myapp"
            keyPassword = "mlekolaki"
        }
        // ⚠️ NIE MA debug!
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") {
            // ⚠️ debug NIE MA signingConfig – użyje domyślnego debug.keystore
        }
    }
}

flutter {
    source = "../.."
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.stylemate"
    compileSdk = flutter.compileSdkVersion
    //ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.stylemate"
        minSdk = 21 // Ensure this is 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // Explicitly include all architectures to prevent "Missing Library" crash
            abiFilters.add("armeabi-v7a")
            abiFilters.add("arm64-v8a")
            abiFilters.add("x86_64")
        }
    }

    // --- PASTE THIS BLOCK HERE ---
    aaptOptions {
        noCompress += listOf("tflite")
    }
    // -----------------------------

    buildTypes {
        getByName("release") {
            // CORRECTION 2: Kotlin syntax uses '=' and 'is' prefix
            isMinifyEnabled = false
            isShrinkResources = false
            
            // CORRECTION 3: Correct way to access signing configs in Kotlin
            signingConfig = signingConfigs.getByName("debug") 
        }
        
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

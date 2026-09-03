import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — see android/key.properties (gitignored; not committed).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fitnessbuddy.fitness_buddy"
    // mobile_scanner's CameraX dependency requires compiling against API 36+
    // (Flutter's own default, flutter.compileSdkVersion, is still 35).
    compileSdk = 36
    // Several plugins (firebase_storage, mobile_scanner, wakelock_plus, ...)
    // require this NDK revision specifically; flutter.ndkVersion resolves
    // lower.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // flutter_local_notifications needs Java 8+ APIs desugared to run
        // on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fitnessbuddy.fitness_buddy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // mobile_scanner requires minSdk 23+ (Android 6.0, 2015) -- Flutter's
        // own default (flutter.minSdkVersion) is 21; API 21/22 share is
        // negligible at this point.
        minSdk = 23
        // Play Console now requires targetSdk 36+ (Flutter's own default,
        // flutter.targetSdkVersion, is still 35).
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key if key.properties isn't present
            // (e.g. a fresh checkout without the release keystore) so
            // `flutter run --release` still works for local testing.
            signingConfig =
                if (keystorePropertiesFile.exists()) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
            // Bundles native (.so) debug symbols into the AAB itself so
            // Play Console can symbolicate native crashes/ANRs without a
            // separate manual symbol-file upload.
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

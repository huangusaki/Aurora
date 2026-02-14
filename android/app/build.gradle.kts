import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    val useReleaseSigning = keystorePropertiesFile.exists()

    if (useReleaseSigning) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        require(!keystoreProperties.getProperty("storeFile").isNullOrBlank()) {
            "Missing `storeFile` in android/key.properties"
        }
        require(!keystoreProperties.getProperty("storePassword").isNullOrBlank()) {
            "Missing `storePassword` in android/key.properties"
        }
        require(!keystoreProperties.getProperty("keyAlias").isNullOrBlank()) {
            "Missing `keyAlias` in android/key.properties"
        }
        require(!keystoreProperties.getProperty("keyPassword").isNullOrBlank()) {
            "Missing `keyPassword` in android/key.properties"
        }
    }

    namespace = "com.aurora.chat"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aurora.chat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resourceConfigurations.addAll(listOf("en", "zh"))
    }

    signingConfigs {
        if (useReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (useReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    // Fallback to debug signing when building locally without `android/key.properties`.
                    signingConfigs.getByName("debug")
                }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

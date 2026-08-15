import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.suseoaa.whoami"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.suseoaa.whoami"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.clear()
            abiFilters.add("arm64-v8a")
        }
    }

    signingConfigs {
        create("releaseKey") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: "suse-app-key"
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: "LinuxisUbuntu18"
            storeFile = if (keystoreProperties.containsKey("storeFile")) {
                file(keystoreProperties.getProperty("storeFile"))
            } else {
                file("/Users/vincent/Desktop/SUSE-APP-Key/APP-Key.jks")
            }
            storePassword = keystoreProperties.getProperty("storePassword") ?: "LinuxisUbuntu18"
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("releaseKey")
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("releaseKey")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

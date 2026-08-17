plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.decorasan_project"
    compileSdk = 36  // تغییر داده شد
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.decorasan_project"
        minSdk = 21  // مقداردهی شد
        targetSdk = 36  // تغییر داده شد
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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
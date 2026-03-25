plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}



android {
    compileSdkVersion 34 // Ou ta version actuelle

    defaultConfig {
        // ... tes configurations actuelles
        multiDexEnabled true // Recommandé avec les grosses lib comme Zego
    }

    compileOptions {
        // Active le support des fonctionnalités Java 8
        coreLibraryDesugaringEnabled true 
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }
}

dependencies {
    // Ajoute cette ligne spécifique pour corriger l'erreur AAR Metadata
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.3'
}
flutter {
    source = "../.."
}

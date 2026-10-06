plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sonara.sonara"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sonara.sonara"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 34
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

tasks.register("verifyNoInternetPermission") {
    description = "Enforces the zero-network invariant by ensuring INTERNET is absent from release manifest"
    doLast {
        val mergedManifest = file("${project.layout.buildDirectory.get()}/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml")
        val altManifest = file("${project.layout.buildDirectory.get()}/intermediates/merged_manifests/release/AndroidManifest.xml")
        val target = if (mergedManifest.exists()) mergedManifest else if (altManifest.exists()) altManifest else null
        if (target != null && target.exists()) {
            val content = target.readText()
            if (content.contains("android.permission.INTERNET")) {
                throw GradleException("FATAL VIOLATION: android.permission.INTERNET detected in release manifest! Sonara is 100% offline.")
            } else {
                println("SUCCESS: Verified merged release manifest contains NO INTERNET permission.")
            }
        }
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy("verifyNoInternetPermission")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

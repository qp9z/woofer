// Imported explicitly: in a Gradle Kotlin script `java` resolves to the Java
// plugin's extension accessor, which shadows the `java.*` package.
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Chaquopy must be applied after the Android plugin, before Flutter's.
    id("com.chaquo.python")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Optional per-machine path to a Python 3.12 for Chaquopy's build toolchain. Read
// at script scope (java.util resolves here, not inside the chaquopy DSL block).
val chaquopyBuildPython: String? = rootProject.file("local.properties").let { f ->
    if (!f.exists()) return@let null
    Properties().apply { f.inputStream().use { load(it) } }
        .getProperty("chaquopy.buildPython")
}

// Release signing. key.properties is gitignored and must not be shared — it holds
// the keystore password. If it's missing (fresh clone, CI), release builds fall
// back to the debug key so `flutter build` still works locally.
val keystoreProperties = rootProject.file("key.properties").let { f ->
    if (!f.exists()) return@let null
    Properties().apply { f.inputStream().use { load(it) } }
}

android {
    namespace = "dev.koulei.woofer"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        if (keystoreProperties != null) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.koulei.woofer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Chaquopy 16 requires minSdk 24; that's higher than Flutter's default, so
        // it's pinned here rather than read from flutter.minSdkVersion.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Chaquopy ships a native CPython per ABI. Python 3.12 only has arm64-v8a
        // and x86_64 builds (32-bit armeabi-v7a was dropped), so limit to those —
        // which also keeps the APK from carrying every interpreter.
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    // yt-dlp is pure Python, so pip resolves it with no native build step.
    chaquopy {
        defaultConfig {
            version = "3.12"
            // Chaquopy 17 needs a Python 3.12 build toolchain. If the host's default
            // python isn't 3.12 (e.g. it's 3.14), install a standalone 3.12
            // (`uv python install 3.12`) and point at it via chaquopy.buildPython in
            // local.properties (gitignored, per-machine). Auto-detected from PATH otherwise.
            chaquopyBuildPython?.let { buildPython(it) }
            pip {
                install("yt-dlp")
            }
        }
    }

    buildTypes {
            release {
                // Sign with the release keystore when key.properties exists; fall back
                // to the debug key if it doesn't (fresh clone/CI) so builds still work.
                signingConfig = if (keystoreProperties != null)
                    signingConfigs.getByName("release")
                else
                    signingConfigs.getByName("debug")
            }
        }
}

flutter {
    source = "../.."
}

dependencies {
    testImplementation("junit:junit:4.13.2")
}

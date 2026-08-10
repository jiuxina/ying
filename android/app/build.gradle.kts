import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val mumuX64Build = providers.gradleProperty("mumu-x64").isPresent

val releaseKeystoreProperties = Properties().apply {
    val envPath = System.getenv("ANDROID_KEYSTORE_PATH")
    if (!envPath.isNullOrBlank()) {
        setProperty("storeFile", envPath)
        setProperty("storePassword", System.getenv("ANDROID_KEYSTORE_PASSWORD").orEmpty())
        setProperty("keyAlias", System.getenv("ANDROID_KEY_ALIAS").orEmpty())
        setProperty("keyPassword", System.getenv("ANDROID_KEY_PASSWORD").orEmpty())
    } else {
        val localFile = rootProject.file("key.properties")
        if (localFile.exists()) {
            load(FileInputStream(localFile))
        }
    }
}

val releaseKeystoreConfigured =
    releaseKeystoreProperties.getProperty("storeFile")?.isNotBlank() == true &&
        releaseKeystoreProperties.getProperty("storePassword")?.isNotBlank() == true &&
        releaseKeystoreProperties.getProperty("keyAlias")?.isNotBlank() == true &&
        releaseKeystoreProperties.getProperty("keyPassword")?.isNotBlank() == true

android {
    namespace = "com.jiuxina.ying"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (releaseKeystoreConfigured) {
            create("release") {
                storeFile = file(releaseKeystoreProperties.getProperty("storeFile"))
                storePassword = releaseKeystoreProperties.getProperty("storePassword")
                keyAlias = releaseKeystoreProperties.getProperty("keyAlias")
                keyPassword = releaseKeystoreProperties.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.jiuxina.ying"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("debug") {
            if (mumuX64Build) {
                ndk.abiFilters.clear()
                ndk.abiFilters += "x86_64"
            }
        }
        release {
            if (releaseKeystoreConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.configureEach {
    if (name == "assembleRelease" || name == "packageRelease") {
        doFirst {
            if (!releaseKeystoreConfigured) {
                throw GradleException(
                    "Release keystore is not configured. Set " +
                        "ANDROID_KEYSTORE_PATH/ANDROID_KEYSTORE_PASSWORD/" +
                        "ANDROID_KEY_ALIAS/ANDROID_KEY_PASSWORD or create " +
                        "android/key.properties.",
                )
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // uCrop 通过 image_cropper 插件编译进应用，远程图片下载依赖 OkHttp。
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    testImplementation("junit:junit:4.13.2")
    // 单元测试使用真实 org.json 实现，避免 android.jar 的 not mocked 桩方法。
    testImplementation("org.json:json:20180813")
}

flutter {
    source = "../.."
}

// Flutter attaches an empty CMake project only to force the NDK download.
// The MuMu build already has the required NDK installed, so skip this no-output
// probe when Windows process injection makes clang crash. Normal builds keep it.
if (mumuX64Build) {
    tasks.configureEach {
        if (
            name.startsWith("configureCMakeDebug") ||
            name.startsWith("buildCMakeDebug")
        ) {
            enabled = false
        }
    }
}

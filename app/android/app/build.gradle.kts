import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. The keystore and its passwords stay outside the repo: the Gradle property `nitznutz.releaseSigning`
// (in ~/.gradle/gradle.properties, or -P on the command line) names a properties file with storeFile, keyAlias,
// storePassword and keyPassword. Nothing from that file is ever printed.
val releaseSigningPath: String? = providers.gradleProperty("nitznutz.releaseSigning").orNull?.takeIf { it.isNotBlank() }
val releaseSigningProps: Properties? = releaseSigningPath?.let { path ->
    val f = file(path)
    if (!f.isFile) throw GradleException("nitznutz.releaseSigning points to a file that does not exist.")
    Properties().apply { f.inputStream().use { load(it) } }
}
fun releaseProp(name: String): String =
    releaseSigningProps?.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("The release signing file has no value for '$name'.")

android {
    namespace = "app.nitznutz.nitznutz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.nitznutz.nitznutz"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        // `dev` is the only flavour that may ever enrol through the dev allowlist (server side),
        // and it installs next to a production build because of the id suffix.
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Nitznutz Dev"
        }
        create("prod") {
            dimension = "env"
            manifestPlaceholders["appName"] = "Nitznutz"
        }
    }

    signingConfigs {
        if (releaseSigningProps != null) {
            create("release") {
                storeFile = file(releaseProp("storeFile"))
                keyAlias = releaseProp("keyAlias")
                storePassword = releaseProp("storePassword")
                keyPassword = releaseProp("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // The prod flavour is signed only with the release key. Without it, the build fails (see the check below)
            // instead of quietly using the debug key. The dev flavour keeps the debug key (it is never shared and the
            // dev allowlist and tools expect it); the choice is made per flavour below.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }

    androidComponents {
        onVariants(selector().withFlavor("env" to "dev")) { variant ->
            // dev release builds stay on the debug key even when the release key is configured.
            if (variant.buildType == "release") {
                variant.signingConfig.setConfig(android.signingConfigs.getByName("debug"))
            }
        }
    }
}

// A prod release build without the release key must fail loudly, never fall back to the debug key.
if (releaseSigningProps == null) {
    gradle.taskGraph.whenReady {
        val prodRelease = allTasks.any { it.project == project && it.name.contains("ProdRelease", ignoreCase = true) &&
            (it.name.startsWith("assemble") || it.name.startsWith("bundle") || it.name.startsWith("package") || it.name.startsWith("sign")) }
        if (prodRelease) {
            throw GradleException(
                "No release signing key: set the Gradle property nitznutz.releaseSigning to the signing properties file " +
                    "(docs/setup/ci-m9.md section 6). A prod release build is never signed with the debug key.")
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

// Push to a parent's phone needs the Firebase client file of the build (kept out of Git: it holds a Google API key). It is
// put in src/dev/ and src/prod/ by hand. Without one the app still builds and runs, and push is simply not offered.
if (file("src/dev/google-services.json").exists() || file("src/prod/google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

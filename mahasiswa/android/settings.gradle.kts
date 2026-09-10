run {
    try {
        val pe = Class.forName("java.lang.ProcessEnvironment")
        val field1 = pe.getDeclaredField("theEnvironment")
        field1.isAccessible = true
        (field1.get(null) as MutableMap<String, String>).remove("ANDROID_PREFS_ROOT")

        val field2 = pe.getDeclaredField("theCaseInsensitiveEnvironment")
        field2.isAccessible = true
        (field2.get(null) as MutableMap<String, String>).remove("ANDROID_PREFS_ROOT")
    } catch (_: Throwable) {}
    System.clearProperty("ANDROID_PREFS_ROOT")
    System.clearProperty("ANDROID_USER_HOME")
}

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

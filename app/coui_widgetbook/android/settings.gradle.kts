rootProject.name = "coui_widgetbook"

pluginManagement {
  val flutterSdkPath: String by lazy {
    val properties = java.util.Properties()
    file("local.properties").inputStream().use { properties.load(it) }
    val path = properties.getProperty("flutter.sdk")
    require(path != null) { "flutter.sdk not set in local.properties" }
    path
  }
  settings.extra["flutterSdkPath"] = flutterSdkPath

  includeBuild("${settings.extra["flutterSdkPath"]}/packages/flutter_tools/gradle")

  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }

  plugins {
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
  }
}

plugins {
  id("dev.flutter.flutter-plugin-loader") version "1.0.0"
  id("com.android.application") version "7.3.0" apply false
}

include(":app")



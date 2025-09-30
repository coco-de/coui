buildscript {
  extra.apply {
    set("kotlin_version", "1.7.10")
  }
  repositories {
    google()
    mavenCentral()
  }
  dependencies {
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${extra["kotlin_version"]}")
  }
}

allprojects {
  repositories {
    google()
    mavenCentral()
  }
}

rootProject.buildDir = "../build"
subprojects {
  project.buildDir = "${rootProject.buildDir}/${project.name}"
  project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
  delete(rootProject.buildDir)
}



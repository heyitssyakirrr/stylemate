buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Your existing dependencies
        classpath("com.android.tools.build:gradle:8.1.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- THIS IS THE MISSING PART (Written in Kotlin) ---

// 1. Tell Gradle to build files into the project's root 'build' folder
rootProject.buildDir = file("../build")

subprojects {
    // 2. Ensure submodules also follow this path
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

subprojects {
    project.evaluationDependsOn(":app")
}

// 3. Register the clean task
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
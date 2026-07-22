allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // receive_sharing_intent hardcodes `compileSdk 37`. AGP 8.11 resolves that to
    // a platform dir named "android-37", but current sdkmanager installs it as
    // "android-37.0", so the build can't find it. Pin plugin modules to an
    // installed platform — nothing here needs API 37 symbols. Registered here
    // (not in a later block) because evaluationDependsOn below evaluates first.
    // ponytail: delete once AGP understands minor-versioned platforms.
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            ?.compileSdkVersion(36)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

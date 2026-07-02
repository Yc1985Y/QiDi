allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            val java11Projects = setOf("flutter_tts", "receive_sharing_intent", "speech_to_text")
            val target = if (project.name in java11Projects) {
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            } else {
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
            jvmTarget.set(target)
        }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// sentry_flutter 8.x pins languageVersion 1.6, which Kotlin 2.x rejects.
// Force every plugin module back to a supported language level.
// blue_thermal_printer 1.2.3 predates AGP 8: no namespace and a legacy
// `package` attribute in its manifest. Patch both at configuration/build time.
subprojects {
    if (name == "blue_thermal_printer") {
        plugins.withId("com.android.library") {
            val android = extensions.findByName("android")
            android?.javaClass
                ?.getMethod("setNamespace", String::class.java)
                ?.invoke(android, "id.tumbuh.pos.blue_thermal")
        }
        tasks.matching { it.name.endsWith("Manifest") }.configureEach {
            doFirst {
                val manifest = file("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val cleaned = manifest.readText()
                        .replace(Regex("package=\"[^\"]+\""), "")
                    manifest.writeText(cleaned)
                }
            }
        }
    }
}

subprojects {
    if (name == "sentry_flutter") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
                apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    fun configureProject(proj: Project) {
        if (proj.hasProperty("android")) {
            val android = proj.extensions.findByName("android")
            if (android != null) {
                try {
                    val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    method.invoke(android, 36)
                } catch (e: Exception) {
                    try {
                        val method = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                        method.invoke(android, 36)
                    } catch (ex: Exception) {
                        // ignore
                    }
                }
            }
        }
    }

    if (state.executed) {
        configureProject(this)
    } else {
        afterEvaluate {
            configureProject(this)
        }
    }

}

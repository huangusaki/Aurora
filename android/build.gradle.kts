allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
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
    
    // Workaround for Isar < 4.0 compatibility with AGP 8+
    if (project.name == "isar_flutter_libs") {
        afterEvaluate {
           val android = project.extensions.getByName("android")
           // Use reflection to set namespace and compileSdk
           android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, "dev.isar.isar_flutter_libs")
           android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(android, 34)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

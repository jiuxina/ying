allprojects {
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (
                requested.group == "androidx.glance" &&
                requested.name == "glance-appwidget"
            ) {
                useVersion("1.1.0")
                because("home_widget 0.8.0 declares 1.+, whose latest alpha requires AGP 9.1 and compileSdk 37")
            }
        }
    }

    repositories {
        maven("https://maven.aliyun.com/repository/google")
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

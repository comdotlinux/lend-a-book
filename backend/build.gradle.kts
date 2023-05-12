import org.apache.tools.ant.taskdefs.condition.Os
import java.nio.file.Files
import java.nio.file.Paths

plugins {
    kotlin("jvm") version "1.8.21"
    kotlin("plugin.allopen") version "1.8.21"
    id("io.quarkus")
}

repositories {
    mavenCentral()
    mavenLocal()
}

val quarkusPlatformGroupId: String by project
val quarkusPlatformArtifactId: String by project
val quarkusPlatformVersion: String by project

dependencies {
    implementation("io.quarkus:quarkus-smallrye-jwt")
    implementation("io.quarkus:quarkus-smallrye-jwt-build")
    implementation(enforcedPlatform("${quarkusPlatformGroupId}:${quarkusPlatformArtifactId}:${quarkusPlatformVersion}"))
    implementation("io.quarkus:quarkus-rest-client-jsonb")
    implementation("io.quarkus:quarkus-hibernate-orm-panache-kotlin")
    implementation("io.quarkus:quarkus-hibernate-validator")
    implementation("io.quarkus:quarkus-smallrye-openapi")
    implementation("io.quarkus:quarkus-kotlin")
    implementation("io.quarkus:quarkus-smallrye-graphql-client")
    implementation("io.quarkus:quarkus-jdbc-postgresql")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("io.quarkus:quarkus-arc")
    implementation("io.quarkus:quarkus-hibernate-orm")
    testImplementation("io.quarkus:quarkus-junit5")
    testImplementation("org.assertj:assertj-core:3.24.2")
}

group = "com.linux"
version = "0.0.1"

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

tasks.withType<Test> {
    systemProperty("java.util.logging.manager", "org.jboss.logmanager.LogManager")
}
allOpen {
    annotation("jakarta.ws.rs.Path")
    annotation("jakarta.enterprise.context.ApplicationScoped")
    annotation("io.quarkus.test.junit.QuarkusTest")
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions.jvmTarget = JavaVersion.VERSION_17.toString()
    kotlinOptions.javaParameters = true
}

tasks.register("hasuraLocal") {
    group = "com.linux"
    description = """Start local stack (localhost:8080).""".trimMargin()
    doLast {
        exec {
            workingDir = project.rootDir
            commandLine("docker compose -f docker-compose.yml up -d".split(" "))
        }
    }
}

tasks.register("stopHasuraLocal") {
    group = "com.linux"
    description = """Start local stack (localhost:8080).""".trimMargin()
    doLast {
        exec {
            workingDir = project.rootDir
            commandLine("docker compose -f docker-compose.yml down".split(" "))
        }
    }
}


tasks.register("hasuraConsole") {
    group = "com.linux"
    description = """Opens the hasuraConsole for editing the already running stack (localhost:8080).""".trimMargin()

    val hasuraDir = project.rootDir.resolve("hasura")
    mustRunAfter(tasks.getByName("hasuraLocal"))

    // TODO: Also maybe check if hasura console is running and kill it to prevent accidentally using wrong instance?
    doLast {
        val browser = properties.getOrDefault("browser", "google-chrome") as String

        val command = listOf("bash", "-c", "hasura console --browser=$browser")
        val processBuilder = ProcessBuilder(command)
        processBuilder.directory(hasuraDir)
        val process = processBuilder.directory(hasuraDir).inheritIO().start()
        logger.lifecycle("-- Spawned Process with pid {} and info : {} --", process.pid(), process.info())

        logger.warn("---- 💡 If The Console is not launched please verify that hasura cli is installed! ----")
    }
}
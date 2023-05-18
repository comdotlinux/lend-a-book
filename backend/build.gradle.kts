import java.nio.file.Files
import java.nio.file.Paths
import java.time.Instant

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
    implementation(
            enforcedPlatform(
                    "${quarkusPlatformGroupId}:${quarkusPlatformArtifactId}:${quarkusPlatformVersion}"
            )
    )
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

tasks.register("startLocal") {
    group = "com.linux"
    description = """Start local stack (localhost:8080).""".trimMargin()
    dependsOn(tasks.findByName("stopLocal"))
    doLast {
        exec {
            workingDir = project.rootDir
            commandLine("docker compose -f docker-compose.yml up -d".split(" "))
        }
    }
}

tasks.register("stopLocal") {
    group = "com.linux"
    description = """👿 Start local stack (localhost:8080).""".trimMargin()
    doLast {
        exec {
            workingDir = project.rootDir
            logger.lifecycle("-- 🥱 Removing container running using docker compose  --")
            commandLine("docker compose -f docker-compose.yml down".split(" "))
        }

        exec {
            logger.lifecycle("-- 🥱 Waiting for docker volume to be removed --")
            val command =
                    """until ! docker volume inspect backend_db_data; do docker volume rm backend_db_data; sleep 3 ; done && echo "";"""
            commandLine("bash", "-c", command)
            isIgnoreExitValue = true
        }
    }
}

val hasuraDir = project.rootDir.resolve("hasura")

tasks.register("startConsole") {
    group = "com.linux"
    description =
            """🎮 Opens the hasuraConsole for editing the already running stack (localhost:8080).""".trimMargin()

    mustRunAfter(tasks.getByName("startLocal"))

    // TODO: Also maybe check if hasura console is running and kill it to prevent accidentally using
    // wrong instance?
    doLast {
        val browser = properties.getOrDefault("browser", "google-chrome") as String

        val command = listOf("bash", "-c", "hasura console --browser=$browser")
        val processBuilder = ProcessBuilder(command)
        processBuilder.directory(hasuraDir)
        val process = processBuilder.directory(hasuraDir).inheritIO().start()
        logger.lifecycle(
                "-- Spawned Process with pid {} and info : {} --",
                process.pid(),
                process.info()
        )

        logger.warn(
                "---- 💡 If The Console is not launched please verify that hasura cli is installed! ----"
        )
    }
}

tasks.register("migrateDown") {
    group = "com.linux"
    description = "⤵ Runs migrate apply --down 1"
    doLast {
        exec {
            workingDir = hasuraDir
            val command =
                    listOf("bash", "-c", "hasura migrate apply --down 1 --database-name default")
            logger.lifecycle("-- ⏬ Running command '{}' --", command)
            commandLine(command)
        }
    }
}

tasks.register("migrateAllUp") {
    group = "com.linux"
    description = "⤴ Runs migrate apply --up all"
    shouldRunAfter(tasks.getByName("migrateDown"))
    doLast {
        exec {
            workingDir = hasuraDir
            val command =
                    listOf("bash", "-c", "hasura migrate apply --up all --database-name default")
            logger.lifecycle("-- ⏫ Running command '{}' --", command)
            commandLine(command)
        }
    }
}

tasks.register("migrateUp") {
    group = "com.linux"
    description = "⤴ Runs migrate apply --up 1"
    shouldRunAfter(tasks.getByName("migrateDown"))
    doLast {
        exec {
            workingDir = hasuraDir
            val command =
                    listOf("bash", "-c", "hasura migrate apply --up 1 --database-name default")
            logger.lifecycle("-- ⏫ Running command '{}' --", command)
            commandLine(command)
        }
    }
}

tasks.register("migrateStatus") {
    group = "com.linux"
    description = "🔍 Runs migrate status"
    doLast {
        exec {
            workingDir = hasuraDir
            val command = listOf("bash", "-c", "hasura migrate status --database-name default")
            logger.lifecycle("-- 🧐 Running command '{}' --", command)
            commandLine(command)
        }
    }
}

tasks.register("reApplyLastMigration") {
    group = "com.linux"
    description =
            " 🔂 Just an alias for running three tasks together, migrateDown, migrateStatus, migrateUp"
    dependsOn(
            tasks.findByName("migrateDown"),
            tasks.findByName("migrateUp"),
            tasks.findByName("migrateStatus")
    )
}

tasks.register("metadataApply") {
    group = "com.linux"
    description = "Ⓜ Runs metadata apply"
    doLast {
        exec {
            workingDir = hasuraDir
            val command = listOf("bash", "-c", "hasura metadata apply")
            logger.lifecycle("-- 🚨 Running command '{}' --", command)
            commandLine(command)
        }
    }
}

tasks.register("seedsApply") {
    group = "com.linux"
    description = "🌱 Runs seeds apply"
    doLast {
        exec {
            workingDir = hasuraDir
            val command = listOf("bash", "-c", "hasura seeds apply --database-name default")
            logger.lifecycle("-- 🚨 Running command '{}' --", command)
            commandLine(command)
        }
    }
}

tasks.register("createEmptyMigrations") {
    group = "com.linux"
    description =
            "🤓 creates empty migrations on default database migrations directory, use -Pname=some_name to create a directory with current epoch and this name"
    val directoryName = properties.getOrDefault("name", "") as String
    doLast {
        val epochTimestamp = Instant.now().toEpochMilli()
        val newMigrationsDirectory =
                Files.createDirectory(
                        Paths.get("$hasuraDir/migrations/default/${epochTimestamp}_$directoryName")
                )
        logger.lifecycle("Created Directory ${newMigrationsDirectory.toAbsolutePath()}")
        if (Files.isDirectory(newMigrationsDirectory)) {
            val upSql = Files.createFile(newMigrationsDirectory.resolve("up.sql"))
            val downSql = Files.createFile(newMigrationsDirectory.resolve("down.sql"))
            logger.lifecycle(
                    "Created Files ${upSql.toAbsolutePath()} and ${downSql.toAbsolutePath()}"
            )
        }
    }
}


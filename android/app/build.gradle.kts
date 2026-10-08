plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.phucta.classroom"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.phucta.classroom"
        minSdk = 26
        targetSdk = 34
        versionCode = 5
        versionName = "0.5-beta"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        manifestPlaceholders["appAuthRedirectScheme"] = "com.phucta.classroom"
    }

    signingConfigs {
        create("release") {
            val keystorePath = System.getenv("KEYSTORE_FILE")
            val customFile = if (!keystorePath.isNullOrEmpty()) file(keystorePath) else null

            if (customFile != null && customFile.exists()) {
                storeFile = customFile
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "android"
                keyAlias = System.getenv("KEY_ALIAS") ?: "androiddebugkey"
                keyPassword = System.getenv("KEY_PASSWORD") ?: "android"
            } else {
                val projectDebugKeystore = file("${project.rootDir}/debug.keystore")
                if (projectDebugKeystore.exists()) {
                    storeFile = projectDebugKeystore
                    storePassword = "android"
                    keyAlias = "androiddebugkey"
                    keyPassword = "android"
                } else {
                    val debugConfig = getByName("debug")
                    val debugStoreFile = debugConfig.storeFile
                    if (debugStoreFile != null && debugStoreFile.exists()) {
                        initWith(debugConfig)
                    } else {
                        val targetKeystore = debugStoreFile ?: file("${System.getProperty("user.home")}/.android/debug.keystore")
                        targetKeystore.parentFile?.mkdirs()
                        if (!targetKeystore.exists()) {
                            try {
                                ProcessBuilder(
                                    "keytool", "-genkeypair",
                                    "-keystore", targetKeystore.absolutePath,
                                    "-alias", "androiddebugkey",
                                    "-keyalg", "RSA",
                                    "-keysize", "2048",
                                    "-validity", "10000",
                                    "-storepass", "android",
                                    "-keypass", "android",
                                    "-dname", "CN=Android Debug,O=Android,C=US"
                                ).start().waitFor()
                            } catch (_: Exception) {}
                        }
                        if (targetKeystore.exists()) {
                            storeFile = targetKeystore
                            storePassword = "android"
                            keyAlias = "androiddebugkey"
                            keyPassword = "android"
                        } else {
                            initWith(debugConfig)
                        }
                    }
                }
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.navigation.compose)

    // Compose BOM
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    debugImplementation(libs.androidx.compose.ui.tooling)

    // Room
    implementation(libs.androidx.room.runtime)
    implementation(libs.androidx.room.ktx)
    ksp(libs.androidx.room.compiler)

    // DataStore & KeyStore
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.security.crypto)

    // Glance (Home Screen Widgets)
    implementation(libs.androidx.glance.appwidget)
    implementation(libs.androidx.glance.material3)

    // WorkManager (Background Sync)
    implementation(libs.androidx.work.runtime.ktx)

    // Chrome Custom Tabs (OAuth)
    implementation(libs.androidx.browser)

    // Network & Serialization
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)

    // Testing
    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}

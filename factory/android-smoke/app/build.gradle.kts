plugins { id("com.android.application") }

android {
    namespace = "com.singularity.nexus.factory"
    compileSdk = 37
    buildToolsVersion = "36.0.0"

    defaultConfig {
        applicationId = "com.singularity.nexus.factory"
        minSdk = 26
        targetSdk = 37
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release { isMinifyEnabled = false }
    }
}

java {
    toolchain { languageVersion.set(JavaLanguageVersion.of(17)) }
}

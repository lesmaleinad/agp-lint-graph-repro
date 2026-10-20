plugins { `kotlin-dsl` }

repositories { mavenCentral() }

dependencies {
    implementation("net.bytebuddy:byte-buddy:1.18.15")
    implementation("net.bytebuddy:byte-buddy-agent:1.18.15")
}

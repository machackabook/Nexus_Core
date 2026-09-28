# Nexus Mobile App Factory v1

Private build authority for reproducible Android and Apple application artifacts.

## Gates

- Android: AGP 9.4.0, Gradle 9.6.0, JDK 17, API 37, Build Tools 36.0.0.
- Apple: GitHub macOS 26 runner, Xcode 26.6, XcodeGen, unsigned iOS Simulator build.

Every successful build emits a SHA-256 receipt and a build manifest. No production signing keys are committed.

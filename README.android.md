# Building the Android app

This fork is a native Krita Android application: C++/Qt, Krita's QWidget/OpenGL
canvas, and a QML control strip. It is **not** a Tauri application. Tauri's
webview packaging cannot replace or wrap the existing native canvas and brush
engine; use Krita's Android packaging pipeline.

## Build an installable debug APK

The GitHub Actions workflow builds the **arm64-v8a** Android APK:

1. Make the repository public before merging the workflow fix. This is required for GitHub's free public runner.
2. Merge the workflow fix into `main`. The merge automatically starts the arm64-v8a build.
3. When it finishes, download the APK artifact from the workflow run. The workflow can also be started manually from **Actions → Build Android APK → Run workflow**.

The workflow uses the documented Linux host-system build procedure from the
Krita manual. It installs Java 17, Android SDK 36, build-tools 36.0.0 and NDK
27.3.13750724, then uses KDE's `krita-deps-management` and
`krita-ci-utilities` repositories to prepare the Android dependency
environment. It builds only the arm64-v8a target, disables tests, and limits
native compilation to two parallel jobs to reduce memory pressure.

The standard GitHub-hosted public Ubuntu runner provides 4 CPUs and 16 GB RAM,
but only 14 GB SSD according to GitHub's published runner specifications.
The workflow removes several unused preinstalled toolchains and reports disk
space at each major stage. Krita's dependency and build footprint may still
exceed the available disk space; the workflow will expose that as a real build
failure rather than pretending a package was produced.

The workflow intentionally builds a **debug APK**. It is intended for
installation and device testing, not Play Store or public distribution. The
Gradle configuration applies the `.debug` application-ID suffix and uses the
debug signing configuration.

## Build environment

Krita's Android build is a native C++/Qt cross-compilation. A generic Android
Studio installation or Gradle invocation alone is insufficient. The build
requires the Android SDK/NDK, Krita's Android CMake toolchain, and the
cross-compiled Qt/KDE/third-party dependency set.

The official build procedure is documented here:

- [Building Krita for Android](https://docs.krita.org/en/untranslatable_pages/building/build_krita_for_android.html)

The source-of-truth packaging files in this repository are:

- `build-tools/ci-scripts/android.yml`
- `build-tools/ci-scripts/build-android-package.py`
- `packaging/android/apk/build.gradle`

## Release status

A successful debug APK build is not a production release. Before public
distribution, decide the app identity and branding, set a project-specific
package ID and version policy, configure protected release signing, and
complete phone/tablet tests for document workflows, stylus pressure/tilt,
palm rejection, gestures, save/recovery, performance and memory behavior.
See [mobile-ui/RELEASE_CHECKLIST.md](mobile-ui/RELEASE_CHECKLIST.md).

# Building the Android app

This fork is a native Krita Android application: C++/Qt, Krita's QWidget/OpenGL
canvas, and a QML control strip. It is **not** a Tauri application. Tauri's
webview packaging cannot replace or wrap the existing native canvas and brush
engine; use Krita's Android packaging pipeline.

## Build an installable debug APK

The recommended entry point is the GitHub Actions workflow:

1. Open the repository's **Actions** tab.
2. Select **Build Android APK**.
3. Choose an ABI. Use `arm64-v8a` for a typical modern Android phone.
4. Run the workflow from the branch/commit you want to test.
5. When it finishes, download the `krita-android-debug-...` artifact from the
   workflow run.

The workflow uses the Android builder image referenced by this repository's
KDE CI configuration, fetches the matching Krita dependency definitions,
builds the checked-out source with the Android Qt 5 toolchain, runs the
existing `create-apk`/Gradle packaging path, and uploads the resulting APK.
Build logs are uploaded separately, including when the compile or packaging
step fails.

Because GitHub only exposes the manual **Run workflow** control after a
`workflow_dispatch` workflow exists on the repository's default branch, merge
the workflow PR into `main` first. Then open **Actions → Build Android APK**,
choose an ABI, and click **Run workflow**.

The workflow intentionally builds **debug APKs only**. They are intended for
installation and device testing, not Play Store or public distribution. The
Gradle configuration applies the `.debug` application-ID suffix and uses the
debug signing configuration.

## Local build environment

Use Linux and the same Android SDK/NDK/Qt/KDE toolchain versions as the
repository's Android CI image. The current Android CI flow expects the
`/var/lib/ci-files/setup-environment.sh` environment file supplied by that
builder image. A generic Android Studio installation by itself is not enough:
Krita also requires its cross-compiled Qt/KDE/third-party dependency tree and
the Krita Android CMake toolchain.

The upstream build guide documents both the prebuilt builder image and the
host-system workflow:

- [Building Krita for Android](https://docs.krita.org/en/untranslatable_pages/building/build_krita_for_android.html)

The source-of-truth CI definitions in this repository are:

- `build-tools/ci-scripts/android.yml`
- `build-tools/ci-scripts/build-android-package.py`
- `packaging/android/apk/build.gradle`

The packaging script expects the completed native install tree and CMake build
tree. Calling Gradle alone does not compile Krita's native application.

## Release status

A successful debug APK build is not a production release. Before public
distribution, decide the app identity and branding, set a project-specific
package ID and version policy, configure protected release signing, and
complete phone/tablet tests for document workflows, stylus pressure/tilt,
palm rejection, gestures, save/recovery, performance and memory behavior.
See [mobile-ui/RELEASE_CHECKLIST.md](mobile-ui/RELEASE_CHECKLIST.md).

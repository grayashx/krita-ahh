# Android release checklist

This repository currently contains Android packaging scaffolding, not a verified
mobile release. Treat every unchecked item below as a release blocker.

## 1. Build inputs

The Android APK Gradle project is in `packaging/android/apk/`. Its
`build.gradle` expects:

- A completed Krita Android build/install tree, supplied through
  `KRITA_INSTALL_PREFIX`.
- An Android ABI through `ANDROID_ABI` (the Gradle project falls back to
  `arm64-v8a` when none is set).
- The Android NDK through `KDECI_ANDROID_NDK_ROOT` or the Gradle
  `ndk.dir` property.
- The Qt Android deployment files and the dependency/toolchain versions used
  by the matching Krita Android build.

The Gradle project packages an already-built Krita install tree. Running
Gradle alone does not compile Krita's C++ sources or prove that the mobile
workspace can launch.

Typical packaging commands, after the native Android install tree exists:

```sh
cd packaging/android/apk
KRITA_INSTALL_PREFIX=/absolute/path/to/android-install \
ANDROID_ABI=arm64-v8a \
KDECI_ANDROID_NDK_ROOT=/absolute/path/to/android-ndk \
./gradlew assembleDebug
```

Use `./gradlew assembleRelease` only after the release signing configuration
and credentials have been set up. Confirm the exact Qt, Android SDK, NDK, and
KDE dependency versions against the native build configuration used to produce
the install tree; do not mix toolchain versions by guesswork.

## 2. Identity, versioning, and signing

The inherited Android packaging configuration currently declares:

- Android namespace and manifest package: `org.krita`.
- Application label: `Krita`.
- Version name: `5.4.0-prealpha`.
- Version code: calculated from the inherited Krita release constants.
- Minimum Android API: 24.
- Target Android API: 36.
- Release build type: code shrinking is enabled.

These are inherited upstream values, not a finalized identity or release
decision for this mobile project. Before any public distribution:

- [ ] Decide the app name, package/application ID, launcher assets, and version
      policy. Do not publish a fork as an official Krita build or imply KDE/Krita
      endorsement.
- [ ] Review the applicable Krita/KDE trademark, attribution, and GPL
      obligations for the chosen distribution and branding.
- [ ] Set a deliberate version name and monotonically increasing version code.
- [ ] Add and verify a release signing configuration. The current Gradle file
      has no project-specific `signingConfigs` block.
- [ ] Keep keystores, passwords, upload keys, and signing credentials out of
      Git. Use a local protected environment or encrypted CI secrets.
- [ ] Verify the signed artifact's package ID, version, certificate, ABI, and
      install/upgrade behavior on a clean device.

The F-Droid Gradle file in this tree is explicitly a placeholder; it is not an
independent release build recipe.

## 3. Required automated checks

- [ ] GitHub Actions mobile source checks pass on the release commit.
- [ ] Run the manual **Build Android APK** workflow for each target ABI.
- [ ] Confirm the workflow builds the checked-out source revision, completes
      the native Android CMake/Krita build, and uploads an APK artifact.
- [ ] Install that debug APK on a physical device and complete the device
      acceptance matrix below.
- [ ] A full native Android CMake/Krita build completes for each ABI being
      distributed.
- [ ] The APK packaging task completes using the install tree from that same
      build.
- [ ] Release APK is signed with the intended certificate.
- [ ] APK contents include the required Qt plugins, Krita resources, fonts,
      translations, MLT files, and native libraries.
- [ ] No test credentials, local paths, debug-only settings, or private signing
      material are present in the artifact.

The checked-in GitHub Actions workflow runs the Python source-level regression
suite. It does not provision the full Qt/KDE Android toolchain and does not
claim an APK build, signing, or runtime test.

## 4. Device acceptance matrix

Complete on at least one phone and one tablet, each in portrait and landscape:

- [ ] Fresh install, first launch, app restart, and upgrade install.
- [ ] Open an existing `.kra` file from recent documents and the Android file
      picker.
- [ ] Create a new canvas through Krita's native new-document dialog.
- [ ] Save a new document, Save As to a different name/location, save an edited
      document again, and export a copy without replacing the native document.
- [ ] Verify the modified marker appears after edits and clears after a
      successful save; verify save cancellation does not falsely mark a save.
- [ ] Open unsupported or damaged files and confirm errors are recoverable.
- [ ] Test JPEG, PNG, WebP, PSD, and other intended import/export formats.
- [ ] Verify pressure, tilt where supported, palm rejection, stylus hover,
      finger pan, pinch zoom, and rotation.
- [ ] Exercise layer creation, rename, ordering, visibility, locks, groups,
      masks, undo, and redo.
- [ ] Exercise brush search, tags, favorites, preset activation, and the native
      Brush Editor.
- [ ] Background and resume the app during an edit and during a save; verify
      autosave/recovery and no document corruption.
- [ ] Test large canvases, large layer trees, large brush libraries, low-memory
      conditions, and long painting sessions for hangs, crashes, and memory
      growth.
- [ ] Verify touch targets, contextual panel scrolling, and canvas area on
      small screens.

## 5. Release decision

A debug APK from the GitHub Actions workflow is a test build, not a release
candidate. A release candidate is ready only when the native Android build,
signed release APK, device acceptance matrix, application identity, versioning,
and licensing/branding review are complete. Static source checks or a successful
debug APK build alone are not a release approval.

#!/usr/bin/env python3
"""Static regression checks for Krita's Android mobile canvas host.

These checks do not replace an Android APK build or physical-device testing.
They guard the source-level contracts that keep QML controls separate from
Krita's native canvas and keep the native touch/tablet event path connected.
"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


class MobileWorkspaceChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.qml = read("mobile-ui/qml/WorkspaceBar.qml")
        cls.bridge_h = read("libs/ui/KisMobileBridge.h")
        cls.bridge_cpp = read("libs/ui/KisMobileBridge.cpp")
        cls.document_header = read("libs/ui/KisDocument.h")
        cls.android_gradle = read("packaging/android/apk/build.gradle")
        cls.android_manifest = read("packaging/android/apk/AndroidManifest.xml")
        cls.android_workflow = read(".github/workflows/build-android-apk.yml")
        cls.gitlab_ci = read(".gitlab-ci.yml")
        cls.root_cmake = read("CMakeLists.txt")
        cls.menu_actions = read("krita/kritamenu.action")
        cls.mobile_qrc = read("mobile-ui/mobile-ui.qrc")
        cls.home_qml = read("mobile-ui/qml/Main.qml")
        cls.main_window_cpp = read("libs/ui/KisMainWindow.cpp")
        cls.view_cpp = read("libs/ui/KisView.cpp")
        cls.canvas_cpp = read("libs/ui/opengl/kis_opengl_canvas2.cpp")
        cls.input_cpp = read("libs/ui/input/kis_input_manager.cpp")
        cls.profile = read("krita/data/input/kritadefault.profile")
        cls.input_tests = read("libs/ui/tests/kis_input_manager_test.cpp")

    def test_qml_function_names_are_unique(self) -> None:
        names = re.findall(r"\bfunction\s+([A-Za-z_$][\w$]*)\s*\(", self.qml)
        duplicates = sorted({name for name in names if names.count(name) > 1})
        self.assertEqual([], duplicates, f"Duplicate QML functions: {duplicates}")

    def test_qml_bridge_calls_have_native_declarations_and_definitions(self) -> None:
        calls = set(re.findall(r"\bkritaBridge\.([A-Za-z_]\w*)\s*\(", self.qml))
        declarations = set(re.findall(
            r"\bQ_INVOKABLE\s+[\w:<>*&]+\s+([A-Za-z_]\w*)\s*\(",
            self.bridge_h,
        ))
        definitions = set(re.findall(
            r"\bKisMobileBridge::([A-Za-z_]\w*)\s*\(",
            self.bridge_cpp,
        ))

        self.assertFalse(sorted(calls - declarations), f"Missing declarations: {sorted(calls - declarations)}")
        self.assertFalse(sorted(calls - definitions), f"Missing definitions: {sorted(calls - definitions)}")

    def test_native_canvas_remains_a_separate_sibling_below_controls(self) -> None:
        controls = self.view_cpp.index("addWidget(mobileControls, 0)")
        canvas = self.view_cpp.index("addWidget(&d->canvasController, 1)")
        self.assertLess(controls, canvas)
        self.assertIn("mobileControls->setMinimumHeight(104)", self.view_cpp)
        self.assertIn("d->canvasController.setMinimumHeight(120)", self.view_cpp)

    def test_opengl_canvas_accepts_touch_and_input_manager_handles_all_phases(self) -> None:
        self.assertIn("setAttribute(Qt::WA_AcceptTouchEvents, true)", self.canvas_cpp)

        for event_name in (
            "TouchBegin",
            "TouchUpdate",
            "TouchEnd",
            "TouchCancel",
            "NativeGesture",
            "TabletPress",
            "TabletMove",
            "TabletRelease",
        ):
            with self.subTest(event=event_name):
                self.assertIn(f"QEvent::{event_name}", self.input_cpp)

    def test_default_profile_has_pan_zoom_rotation_and_touch_mappings(self) -> None:
        for section in (
            "[Pan Canvas]",
            "[Zoom Canvas]",
            "[Rotate Canvas]",
            "[Zoom and Rotate Canvas]",
            "[Touch Gestures]",
        ):
            with self.subTest(section=section):
                self.assertIn(section, self.profile)

    def test_short_screen_and_narrow_width_layout_fallbacks_exist(self) -> None:
        self.assertIn("compactWidth: width < 420", self.qml)
        self.assertIn("compactHeight: height < 260", self.qml)
        self.assertIn("contextPanelHeight", self.qml)
        self.assertIn("Flickable {", self.qml)

    def test_existing_touch_and_pen_regressions_remain_in_input_suite(self) -> None:
        self.assertIn("testTouchMoves", self.input_tests)
        self.assertIn("testTouchOverriddenByTablet", self.input_tests)

    def test_document_metadata_and_save_as_use_native_document_apis(self) -> None:
        for method in ("documentTitle", "documentModified", "saveDocumentAs"):
            with self.subTest(method=method):
                self.assertRegex(self.bridge_h, rf"Q_INVOKABLE\s+[^;]+\b{method}\s*\(")
                self.assertIn(f"KisMobileBridge::{method}(", self.bridge_cpp)

        self.assertIn("void documentMetadataChanged();", self.bridge_h)
        self.assertIn("QPointer<KisDocument> m_connectedDocument", self.bridge_h)
        self.assertIn("void modified(bool);", self.document_header)
        self.assertIn("void sigPathChanged(const QString &path);", self.document_header)
        self.assertIn("void sigSavingFinished(const QString &filePath);", self.document_header)
        self.assertIn("&KisDocument::modified", self.bridge_cpp)
        self.assertIn("&KisDocument::sigPathChanged", self.bridge_cpp)
        self.assertIn("&KisDocument::sigSavingFinished", self.bridge_cpp)
        self.assertIn("->caption()", self.bridge_cpp)
        self.assertIn("->isModified()", self.bridge_cpp)
        self.assertIn("m_mainWindow->saveDocument(", self.bridge_cpp)

    def test_workspace_displays_live_document_metadata_and_save_as(self) -> None:
        self.assertIn("root.documentTitle", self.qml)
        self.assertIn("root.documentModified", self.qml)
        self.assertIn("onDocumentMetadataChanged()", self.qml)
        self.assertIn("kritaBridge.saveDocumentAs()", self.qml)
        self.assertIn('text: "Save as…"', self.qml)

    def test_brush_catalogue_search_is_debounced_and_contextual(self) -> None:
        self.assertIn("interval: 220", self.qml)
        self.assertIn("onTextChanged: presetSearchDebounce.restart()", self.qml)
        self.assertIn('root.activePanel === "brushes"', self.qml)
        self.assertIn('root.activePanel === "layers"', self.qml)

    def test_android_release_identity_and_build_configuration_are_explicit(self) -> None:
        namespace = re.search(r'namespace\s*=\s*"([^"]+)"', self.android_gradle)
        manifest_package = re.search(r'<manifest[^>]*package="([^"]+)"', self.android_manifest)
        self.assertIsNotNone(namespace)
        self.assertIsNotNone(manifest_package)
        self.assertEqual(namespace.group(1), manifest_package.group(1))
        self.assertRegex(self.android_gradle, r"minSdkVersion\s+\d+")
        self.assertRegex(self.android_gradle, r"targetSdkVersion\s+\d+")
        self.assertRegex(self.android_gradle, r'versionName\s+"[^"]+"')
        self.assertRegex(self.android_gradle, r"versionCode\s+")
        self.assertIn("release {", self.android_gradle)

    def test_android_requires_qt_quick_host_dependencies(self) -> None:
        for component in ("Quick", "QuickWidgets", "QuickControls2"):
            with self.subTest(component=component):
                requirement = "find_package(Qt${QT_MAJOR_VERSION}" + component + " ${MIN_QT_VERSION} REQUIRED)"
                self.assertIn(requirement, self.root_cmake)

    def test_mobile_home_actions_and_qml_resources_are_registered(self) -> None:
        self.assertIn('<Action name="file_new">', self.menu_actions)
        self.assertIn('<Action name="file_open">', self.menu_actions)
        self.assertIn('root.dispatch("file_new")', self.home_qml)
        self.assertIn('root.dispatch("file_open")', self.home_qml)
        self.assertIn('root.dispatch("openRecent", index)', self.home_qml)
        self.assertIn('alias="Main.qml"', self.mobile_qrc)
        self.assertIn('alias="WorkspaceBar.qml"', self.mobile_qrc)
        self.assertIn('qrc:/mobile-ui/qml/Main.qml', self.main_window_cpp)
        self.assertIn('qrc:/mobile-ui/qml/WorkspaceBar.qml', self.view_cpp)

    def test_android_debug_apk_workflow_uses_native_krita_build_pipeline(self) -> None:
        self.assertIn("workflow_dispatch:", self.android_workflow)
        self.assertIn("KDE_ANDROID_IMAGE: s3.kde.org/ci-vm-images/krita-android-sdk36-2204", self.android_workflow)
        self.assertNotIn("storage.kde.org/vm-images/krita-android-sdk36-2204", self.android_workflow)
        self.assertIn("VM_IMAGE_NAME_ANDROID: 's3.kde.org/ci-vm-images/krita-android-sdk36-2204'", self.gitlab_ci)
        self.assertNotIn("storage.kde.org/vm-images/krita-android-sdk36-2204", self.gitlab_ci)
        self.assertIn("run-ci-build.py", self.android_workflow)
        self.assertIn("build-android-package.py", self.android_workflow)
        self.assertIn("export KRITACI_ANDROID_PACKAGE_TYPE=debug", self.android_workflow)
        self.assertIn("actions/upload-artifact@v7", self.android_workflow)
        self.assertIn("arm64-v8a", self.android_workflow)
        self.assertIn("actions/checkout@v7", self.android_workflow)
        self.assertNotIn("Tauri", self.android_workflow)

if __name__ == "__main__":
    unittest.main(verbosity=2)

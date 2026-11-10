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


if __name__ == "__main__":
    unittest.main(verbosity=2)

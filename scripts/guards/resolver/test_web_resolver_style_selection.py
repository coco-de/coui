#!/usr/bin/env python3
"""RULE E picks a component contract before a child style without hiding gaps."""

import pathlib
import subprocess
import tempfile
import unittest

GUARD = pathlib.Path(__file__).with_name('check_web_resolver.sh').resolve()


class ResolverStyleSelectionTest(unittest.TestCase):
    def run_guard(self, *, own_used=True, child_used=False, fallback=False):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            contracts = root / 'packages/coui_core/lib/src/component/contracts'
            resolver = root / 'packages/coui_web/lib/src/components/form/input_otp'
            contracts.mkdir(parents=True)
            resolver.mkdir(parents=True)
            (contracts / 'own.dart').write_text('''
class CoreInputOtpStyle {
  const CoreInputOtpStyle({this.ownColor});
  final Object? ownColor;
}
class CoreOutlinedContainerStyle {
  const CoreOutlinedContainerStyle({this.childColor});
  final Object? childColor;
}
''')
            own = '' if fallback else 'CoreInputOtpStyle? inputOtpStyle;\n'
            used = 'merged.ownColor;' if own_used else ''
            child = 'merged.childColor;' if child_used else ''
            (resolver / 'input_otp_style.dart').write_text(
                'const CoreOutlinedContainerStyle();\n' + own + used + child
            )
            return subprocess.run(
                ['bash', str(GUARD), str(resolver)],
                cwd=root,
                text=True,
                capture_output=True,
                check=False,
            )

    def test_child_style_does_not_replace_component_contract(self):
        result = self.run_guard()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("'childColor'", result.stdout)

    def test_missing_component_override_remains_a_failure(self):
        result = self.run_guard(own_used=False, child_used=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("'ownColor'", result.stdout)
        self.assertNotIn("'childColor'", result.stdout)

    def test_legacy_fallback_still_checks_selected_style(self):
        result = self.run_guard(own_used=False, fallback=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("'childColor'", result.stdout)

    def test_nested_disabled_icon_override_must_be_checked(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            resolver = root / 'packages/coui_web/lib/src/components/form/item_picker'
            resolver.mkdir(parents=True)
            source = resolver / 'item_picker_style.dart'
            prefix = 'CoreItemPickerStyle.defaultDisabledSearchIconColor;\n'
            condition = 'final keep = merged.searchIconStyle?.color != null;\n'
            source.write_text(prefix + condition)
            run = lambda: subprocess.run(
                ['bash', str(GUARD), str(resolver)], cwd=root,
                text=True, capture_output=True, check=False,
            )
            checked = run()
            self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)
            source.write_text(prefix)
            missing = run()
            self.assertNotEqual(missing.returncode, 0)
            self.assertIn("'disabledSearchIconColor'", missing.stdout)
            source.write_text(prefix + '// ' + condition)
            commented = run()
            self.assertNotEqual(commented.returncode, 0)
            self.assertIn("'disabledSearchIconColor'", commented.stdout)


if __name__ == '__main__':
    unittest.main()

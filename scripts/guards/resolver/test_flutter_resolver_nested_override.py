#!/usr/bin/env python3
"""The ItemPicker nested-color exception requires a live override check."""

from pathlib import Path
import subprocess
import tempfile
import unittest

GUARD = Path(__file__).with_name('check_flutter_resolver.sh').resolve()


class NestedIconOverrideTest(unittest.TestCase):
    def test_condition_is_required_and_comments_do_not_count(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            resolver = root / 'packages/coui_flutter/lib/src/components/form/item_picker'
            resolver.mkdir(parents=True)
            source = resolver / 'item_picker_style.dart'
            default = 'CoreItemPickerStyle.defaultDisabledSearchIconColor;\n'
            condition = 'final keep = merged.searchIconStyle?.color != null;\n'

            def run():
                return subprocess.run(
                    ['bash', str(GUARD), str(resolver)], cwd=root,
                    text=True, capture_output=True, check=False,
                )

            source.write_text(default + condition)
            checked = run()
            self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)
            for missing_condition in ('', '// ' + condition):
                source.write_text(default + missing_condition)
                missing = run()
                self.assertNotEqual(missing.returncode, 0)
                self.assertIn("'disabledSearchIconColor'", missing.stdout)


if __name__ == '__main__':
    unittest.main()

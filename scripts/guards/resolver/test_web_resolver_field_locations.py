#!/usr/bin/env python3
"""Rule C reports the actual field location without changing its categories."""

import pathlib
import subprocess
import tempfile
import unittest

GUARD = pathlib.Path(__file__).with_name('check_web_resolver.sh').resolve()


class ResolverFieldLocationsTest(unittest.TestCase):
    def test_field_location_survives_category_regexes(self):
        source = '''// Header before the class.
// The class need not begin on the first line.

class ResolvedFixture implements WebResolvedChrome {
  const ResolvedFixture();
  final WebElementChrome root;
  final String unsafeScalar;
}

class ResolvedOther {
  final WebElementChrome root;
  final double unsafeSize;
}
'''
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            resolver = root / 'fixture_style.dart'
            resolver.write_text(source)
            result = subprocess.run(
                ['bash', str(GUARD), str(resolver)],
                cwd=root, text=True, capture_output=True, check=False,
            )
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertEqual(result.stderr, '')
            for field in ('unsafeScalar', 'unsafeSize'):
                expected_line = next(
                    i for i, line in enumerate(source.splitlines(), 1)
                    if f' {field};' in line
                )
                self.assertIn(f'{resolver}:{expected_line}  ', result.stdout)
            self.assertIn('ResolvedFixture.unsafeScalar [String]', result.stdout)
            self.assertIn('ResolvedOther.unsafeSize [double]', result.stdout)
            self.assertIn('2 개 위반', result.stdout)


if __name__ == '__main__':
    unittest.main()

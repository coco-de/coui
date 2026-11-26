#!/usr/bin/env python3
"""Regression tests for PhoneInput's chromeless number-field forward."""

import copy
import importlib.util
import io
import json
import pathlib
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

PATH = pathlib.Path(__file__).with_name("check_chromeless_composition.py")
SPEC = importlib.util.spec_from_file_location("chromeless_guard", PATH)
assert SPEC is not None and SPEC.loader is not None
GUARD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GUARD)


class PhoneInputAliasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.doc = json.loads(GUARD.DATA.read_text())["components"]
        cls.source = (GUARD.BUILDERS / "form-fields.ts").read_text()
        cls.core = GUARD.PHONE_STYLE.read_text()

    def errors(self, *, source=None, core=None, doc=None):
        return GUARD.phone_alias_forwarded(
            self.doc if doc is None else doc,
            self.source if source is None else source,
            self.core if core is None else core,
        )

    def test_actual_default_aliases_and_both_applications(self):
        self.assertEqual(self.errors(), [])

    def test_missing_number_application_is_not_credited_by_search(self):
        code = "suppressFieldChrome(field, lk, f.numberFieldStyle);"
        self.assertIn(code, self.source)
        source = self.source.replace(code, "// " + code, 1)
        self.assertIn("PhoneInput number application missing", self.errors(source=source))

    def test_number_default_must_be_the_chromeless_alias(self):
        needle = "defaultNumberFieldStyle = chromelessFieldStyle"
        self.assertIn(needle, self.core)
        core = self.core.replace(needle, "defaultNumberFieldStyle = OtherStyle", 1)
        self.assertIn(
            "PhoneInput defaultNumberFieldStyle alias missing", self.errors(core=core)
        )

    def test_exported_defaults_must_match_chromeless(self):
        for name in ("numberFieldStyle",):
            with self.subTest(name=name):
                doc = copy.deepcopy(self.doc)
                doc["phone_input"]["fields"][name]["borderWidth"]["v"] = 1
                self.assertIn(f"PhoneInput {name} is not chromeless", self.errors(doc=doc))

    def test_guard_rejects_each_missing_application_end_to_end(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            src = root / "tools/figma-token-sync/src"
            builders = src / "components"
            builders.mkdir(parents=True)
            (src / "helper.ts").write_text(
                "export function suppressFieldChrome(x) { x.fills = []; x.strokes = []; }"
            )
            for index in range(4):
                (builders / f"fixture{index}.ts").write_text("")
            source_path = builders / "form-fields.ts"
            data_path = root / "components.json"
            phone = self.doc["phone_input"]
            data_path.write_text(json.dumps({"components": {"phone_input": {
                "constants": {"chromelessFieldStyle": phone["constants"]["chromelessFieldStyle"]},
                "fields": {key: phone["fields"][key] for key in (
                    "numberFieldStyle", "searchFieldStyle")},
            }}}))
            core_path = root / "phone_input_style.dart"
            core_path.write_text(self.core)
            with mock.patch.multiple(
                GUARD, ROOT=root, DATA=data_path, BUILDERS=builders,
                PHONE_STYLE=core_path, UNREAD_ALLOWLIST=root / "missing.json",
            ):
                with redirect_stdout(io.StringIO()):
                    source_path.write_text(self.source)
                    self.assertEqual(GUARD.main(), 0)
                    for code in (
                        "suppressFieldChrome(field, lk, f.numberFieldStyle);",
                    ):
                        with self.subTest(code=code):
                            source_path.write_text(
                                self.source.replace(code, "/* " + code + " */", 1)
                            )
                            self.assertEqual(GUARD.main(), 1)


if __name__ == "__main__":
    unittest.main()

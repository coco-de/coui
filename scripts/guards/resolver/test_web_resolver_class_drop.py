#!/usr/bin/env python3
"""RULE F distinguishes Dart code and proven color/selector values."""

import pathlib
import shutil
import subprocess
import tempfile
import unittest

from web_class_drop import Checker, ScanError


GUARD = pathlib.Path(__file__).with_name('check_web_resolver.sh').resolve()
COLOR_IMPORT = "import 'package:coui_web/src/util/core_to_css.dart';\n"


class ClassDropTest(unittest.TestCase):
    def assert_drop(self, source, count=1):
        self.assertEqual(len(list(Checker(source).violations())), count, source)

    def assert_clear(self, source):
        self.assert_drop(source, 0)

    def test_dimensional_literal_alias_and_multiline_remain_failures(self):
        for source in (
            "String f(bool raw) => raw ? '' : 'rounded-xl';",
            "const width = 'w-8'; String f(bool raw) => raw ? '' : width;",
            "const gap = 'gap-2'; String f(bool raw) => raw\n ? ''\n : gap;",
            "String f(bool raw) => 'prefix ${raw ? '' : 'px-4'}';",
            "String f(bool raw, String value) => raw ? '' : value;",
            "String f(bool raw) => raw ? '' : 'text-sm rounded-xl';",
            "String f(bool raw) => raw ? '' : 'bg-primary gap-2';",
            "String f(bool raw) => raw ? '' : 'ring-2 w-8';",
            "String f(bool raw, String size) => raw ? ('') : size;",
            "String f(bool raw) => raw ? '' : 'bg-${unknown + color.tailwindColor}';",
            "String f(bool raw) => raw ? '' : 'bg-${condition ? size : color.tailwindColor}';",
            "String f(bool raw) => raw ? '' : 'text-${unknown + resolved.token!.name}';",
        ):
            with self.subTest(source=source):
                self.assert_drop(source)

    def test_color_words_outside_branch_do_not_exempt_dimensions(self):
        for source in (
            "String f(bool raw, String size) => raw ? '' : size /* bg- text- */;",
            "String f(bool raw, String size) => raw ? '' : size; // bg-primary",
            "List f(bool raw, String size) => [raw ? '' : size, 'bg-primary'];",
        ):
            with self.subTest(source=source):
                self.assert_drop(source)

    def test_comments_and_noninterpolated_strings_are_not_code(self):
        for source in (
            "// example raw ? '' : sizeClass;\nString f() => 'ok';",
            "/* outer /* raw ? '' : size; */ still comment */ String f()=>'';",
            'String f() => "example raw ? \'\' : sizeClass;";',
            'String f() => r"example ${raw ? \'\' : sizeClass};";',
            'String f() => """example raw ? \'\' : sizeClass;""";',
            r'''String f() => 'escaped \' raw ? "" : size;';''',
            "String f(String? value) => value ?? '';",
        ):
            with self.subTest(source=source):
                self.assert_clear(source)

    def test_actual_selector_suffix_is_not_a_dimensional_class(self):
        self.assert_clear("""
String f(String id, String guard) => rules(
  rootSelector: '#$id${guard.isEmpty ? '' : ':where(.$guard)'}',
  count: 2,
);
""")
        self.assert_drop("""
String f(bool raw, String guard) =>
  raw ? '' : ':where(.$guard) rounded-xl';
""")

    def test_canonical_emitter_and_immutable_aliases_are_color_proof(self):
        for value in (
            'emitted.className',
            'alias.className',
            'classes',
            'emitColor(input, fallback, .border).className',
            "'border ${emitted.className}'",  # literal border width is not color
        ):
            source = COLOR_IMPORT + """
String f(bool raw, dynamic input, dynamic fallback) {
  final emitted = emitColor(input, fallback, .border);
  final alias = emitted;
  final classes = alias.className;
  return raw ? '' : VALUE;
}
""".replace('VALUE', value)
            with self.subTest(value=value):
                if value.startswith("'border "):
                    self.assert_drop(source)
                else:
                    self.assert_clear(source)

    def test_actual_color_picker_interpolation_and_typography(self):
        self.assert_clear(COLOR_IMPORT + """
String f(bool triggerEdgeUsesVariable, dynamic merged, dynamic fallback) {
  final borderColorEmit = emitColor(merged.borderColor, fallback, .border);
  return [
    'border ${triggerEdgeUsesVariable ? '' : borderColorEmit.className}',
    'transition-colors',
  ].join(' ');
}
""")
        self.assert_clear(COLOR_IMPORT + """
String f(bool raw, dynamic input, dynamic fallback) {
  final words = emitTypography(input, fallback);
  return raw ? '' : words.className;
}
""")

    def test_existing_literal_color_and_typography_forms_remain_allowed(self):
        for value in (
            "'bg-primary text-sm'",
            "' ring-2 ring-${color.tailwindColor}'",
            "'text-${resolved.token!.name}'",
        ):
            with self.subTest(value=value):
                self.assert_clear("String f(bool raw) => raw ? '' : " + value + ';')

    def test_nearest_scope_shadow_mutation_and_unknown_emitter_fail(self):
        for source in (
            """
String f(bool raw, dynamic input, dynamic fallback) {
  final emitted = emitColor(input, fallback, .border);
  String nested(dynamic emitted) { return raw ? '' : emitted.className; }
  return '';
}
""",
            """
void first() { final emitted = emitColor(null, null, .border); }
String second(bool raw, dynamic emitted) => raw ? '' : emitted.className;
""",
            """
String f(bool raw, dynamic input, dynamic fallback) {
  final emitted = emitColor(input, fallback, .border);
  { dynamic emitted = input; return raw ? '' : emitted.className; }
}
""",
            """
String f(bool raw) {
  var emitted = emitColor(null, null, .border);
  emitted = unknown;
  return raw ? '' : emitted.className;
}
""",
            """
String f(bool raw) {
  final emitted = emitColor(null, null, .border);
  emitted = unknown;
  return raw ? '' : emitted.className;
}
""",
            """
String f(bool raw, dynamic emitColor) {
  final emitted = emitColor(null, null, .border);
  return raw ? '' : emitted.className;
}
""",
            """
String f(bool raw, dynamic inputs) {
  final emitted = emitColor(null, null, .border);
  for (final emitted in inputs) { return raw ? '' : emitted.className; }
  return '';
}
""",
            """
String f(bool raw, dynamic input) {
  final emitted = emitColor(null, null, .border);
  { final (emitted, other) = input; return raw ? '' : emitted.className; }
}
""",
            """
String f(bool raw, dynamic inputs) {
  final emitted = emitColor(null, null, .border);
  for (dynamic emitted in inputs) { return raw ? '' : emitted.className; }
  return '';
}
""",
            """
String f(bool raw, dynamic input) {
  final emitted = emitColor(null, null, .border);
  if (input case final emitted) { return raw ? '' : emitted.className; }
  return '';
}
""",
        ):
            with self.subTest(source=source):
                self.assert_drop(COLOR_IMPORT + source)
        self.assert_drop("String f(bool raw, dynamic emitted) => raw ? '' : emitted.className;")

    def test_inner_alias_does_not_poison_valid_outer_owner(self):
        self.assert_clear(COLOR_IMPORT + """
String f(bool raw) {
  final emitted = emitColor(null, null, .border);
  { final emitted = 'w-8'; }
  return raw ? '' : emitted.className;
}
""")

    def test_type_owner_withholds_inherited_or_mixin_emitter_proof(self):
        self.assert_drop(COLOR_IMPORT + """
class Parent {
  dynamic emitColor(dynamic value, dynamic fallback, dynamic target) =>
    (className: 'rounded-xl', inline: null);
}
class Child extends Parent {
  String f(bool raw) {
    final value = emitColor(null, null, null);
    return raw ? '' : value.className;
  }
}
""")
        # The member's declaration may live in another library. A lexical
        # import match cannot prove that these calls reach the imported helper.
        declarations = (
            'class Child extends ExternalBase',
            'class Child with ExternalMixin',
            'mixin LocalMixin on ExternalBase',
            'extension LocalExtension on ExternalBase',
            ('extension type LocalType(ExternalBase value)'
             ' implements ExternalBase'),
            'enum LocalEnum with ExternalMixin',
        )
        for declaration in declarations:
            body = """
  String f(bool raw) {
    final value = emitColor(null, null, .border);
    String nested() => raw ? '' : value.className;
    return nested();
  }
"""
            if declaration.startswith('enum '):
                body = 'item;\n' + body
            with self.subTest(declaration=declaration):
                self.assert_drop(COLOR_IMPORT + declaration + ' {' + body + '}')
        self.assert_drop("""
import 'package:coui_web/src/util/core_to_css.dart' as css;
class Child extends ExternalBase {
  String f(bool raw) {
    final value = css.emitColor(null, null, .border);
    return raw ? '' : value.className;
  }
}
""")

    def test_top_level_resolver_and_local_closure_keep_emitter_proof(self):
        self.assert_clear(COLOR_IMPORT + """
class UnrelatedType { const UnrelatedType(); }
class Alias = ExternalBase with ExternalMixin;
String resolver(bool raw) {
  final value = emitColor(null, null, .border);
  String local() => raw ? '' : value.className;
  return local();
}
""")

    def test_import_prefix_show_hide_and_local_function_shadow(self):
        self.assert_clear("""
import 'package:coui_web/src/util/core_to_css.dart' as css;
String f(bool raw) => raw ? '' : css.emitColor(null, null, .border).className;
""")
        self.assert_drop("""
import 'package:coui_web/src/util/core_to_css.dart' hide emitColor;
String f(bool raw) => raw ? '' : emitColor(null, null, .border).className;
""")
        self.assert_drop(COLOR_IMPORT + """
dynamic emitColor(dynamic a, dynamic b, dynamic c) => unknown;
String f(bool raw) => raw ? '' : emitColor(null, null, .border).className;
""")
        self.assert_drop("""
import 'package:coui_web/src/util/core_to_css.dart'
  if (dart.library.io) 'unknown.dart';
String f(bool raw) => raw ? '' : emitColor(null, null, .border).className;
""")

    def test_unknown_scoped_state_class_remains_unresolved(self):
        self.assert_drop("""
String f(bool enabled, bool selected) => !enabled ? '' : selected
  ? selectedStateLayerScopeClass : stateLayerScopeClass;
""")

    def test_unclosed_source_is_an_error_not_a_clean_scan(self):
        for source in ("/* raw ? '' : width;", "String f() => 'unterminated",
                       "String f() => '${raw ? '' : width';", "void f() {"):
            with self.subTest(source=source):
                with self.assertRaises(ScanError):
                    Checker(source)

    def test_standalone_guard_fixture_requires_no_dart_or_pubspec(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            resolver = root / 'example_style.dart'
            resolver.write_text(COLOR_IMPORT + """
String f(bool raw) {
  final value = emitColor(null, null, .border);
  return raw ? '' : value.className;
}
""")
            result = subprocess.run(['bash', str(GUARD), str(resolver)], cwd=root,
                                    text=True, capture_output=True, check=False)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            resolver.write_text("String f(bool raw, String size) => raw ? '' : size;")
            result = subprocess.run(['bash', str(GUARD), str(resolver)], cwd=root,
                                    text=True, capture_output=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('[class-drop', result.stdout)

    def test_helper_error_is_propagated_by_bash(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            resolver = root / 'example_style.dart'
            resolver.write_text('/* unclosed')
            result = subprocess.run(['bash', str(GUARD), str(resolver)], cwd=root,
                                    text=True, capture_output=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('source scan failed', result.stderr)
            # A missing scanner must not be swallowed by process substitution.
            copied_guard = root / GUARD.name
            shutil.copyfile(GUARD, copied_guard)
            resolver.write_text('')
            result = subprocess.run(['bash', str(copied_guard), str(resolver)],
                                    cwd=root, text=True, capture_output=True,
                                    check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('source scan failed', result.stderr)


if __name__ == '__main__':
    unittest.main()

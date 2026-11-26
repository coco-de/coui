import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/prefer_k_prefixed_global_constant_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferKPrefixedGlobalConstantRuleTest);
  });
}

@reflectiveTest
class PreferKPrefixedGlobalConstantRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferKPrefixedGlobalConstantRule();
    super.setUp();
  }

  Future<void> test_flags_unprefixed_constant() async {
    final content = 'const defaultPadding = 16.0;\n';
    await assertDiagnostics(content, [
      lint(content.indexOf('defaultPadding'), 'defaultPadding'.length),
    ]);
  }

  Future<void> test_flags_unprefixed_private_constant() async {
    final content =
        'const _defaultPadding = 16.0;\n'
        'double get padding => _defaultPadding;\n';
    await assertDiagnostics(content, [
      lint(content.indexOf('_defaultPadding'), '_defaultPadding'.length),
    ]);
  }

  Future<void> test_allows_k_prefixed_constants() async {
    await assertNoDiagnostics(r'''
const kDefaultPadding = 16.0;
const _kGap = 8.0;
double get gap => _kGap;
''');
  }

  Future<void> test_allows_annotation_constant() async {
    await assertNoDiagnostics(r'''
class Immutable {
  const Immutable();
}
const immutable = Immutable();
''');
  }

  Future<void> test_flags_constant_that_only_looks_like_an_annotation() async {
    final content = r'''
class Padding {
  const Padding();
}
const defaultPadding = Padding();
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('defaultPadding'), 'defaultPadding'.length),
    ]);
  }

  Future<void> test_ignores_non_const_top_level() async {
    await assertNoDiagnostics(r'''
final cache = <int>[];
''');
  }

  Future<void> test_ignores_static_class_constant() async {
    await assertNoDiagnostics(r'''
class Tokens {
  static const space16 = 16.0;
}
''');
  }
}

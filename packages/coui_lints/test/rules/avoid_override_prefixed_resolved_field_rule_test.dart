import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/avoid_override_prefixed_resolved_field_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidOverridePrefixedResolvedFieldRuleTest);
  });
}

@reflectiveTest
class AvoidOverridePrefixedResolvedFieldRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidOverridePrefixedResolvedFieldRule();
    super.setUp();
  }

  Future<void> test_flags_override_prefixed_field() async {
    final content = r'''
class ResolvedFoo {
  final Object? overrideBackgroundColor;
  ResolvedFoo(this.overrideBackgroundColor);
}
''';
    await assertDiagnostics(content, [
      lint(
        content.indexOf('overrideBackgroundColor;'),
        'overrideBackgroundColor'.length,
      ),
    ]);
  }

  Future<void> test_allows_non_prefixed_field() async {
    await assertNoDiagnostics(r'''
class ResolvedFoo {
  final Object? backgroundColor;
  ResolvedFoo(this.backgroundColor);
}
''');
  }

  Future<void> test_allows_override_prefix_outside_resolved_class() async {
    await assertNoDiagnostics(r'''
class FooStyle {
  final Object? overrideBackgroundColor;
  FooStyle(this.overrideBackgroundColor);
}
''');
  }
}

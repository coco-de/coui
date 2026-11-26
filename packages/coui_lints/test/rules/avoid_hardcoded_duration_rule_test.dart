import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/avoid_hardcoded_duration_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHardcodedDurationRuleTest);
  });
}

@reflectiveTest
class AvoidHardcodedDurationRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidHardcodedDurationRule();
    super.setUp();
  }

  Future<void> test_flags_raw_milliseconds_literal() async {
    final content = r'''
// ignore_for_file: unused_element
const _d = Duration(milliseconds: 200);
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('milliseconds: 200'), 'milliseconds: 200'.length),
    ]);
  }

  Future<void> test_allows_core_duration_token() async {
    await assertNoDiagnostics(r'''
class CoreDuration {
  static const ms200 = 200;
}

const d = Duration(milliseconds: CoreDuration.ms200);
''');
  }

  Future<void> test_allows_k_prefixed_local_constant() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_element
const _kDefaultDuration = Duration(milliseconds: 200);
''');
  }
}

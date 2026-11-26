import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/avoid_local_token_constant_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidLocalTokenConstantRuleTest);
  });
}

@reflectiveTest
class AvoidLocalTokenConstantRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLocalTokenConstantRule();
    super.setUp();
  }

  Future<void> test_flags_k_prefixed_core_space_alias() async {
    final content = r'''
// ignore_for_file: unused_element
class CoreSpace {
  static const double space16 = 16;
}

const _kDefaultPadding = CoreSpace.space16;
''';
    await assertDiagnostics(content, [
      lint(
        content.indexOf('_kDefaultPadding = CoreSpace.space16'),
        '_kDefaultPadding = CoreSpace.space16'.length,
      ),
    ]);
  }

  Future<void> test_allows_non_k_prefixed_constant() async {
    await assertNoDiagnostics(r'''
class CoreSpace {
  static const double space16 = 16;
}

const defaultPadding = CoreSpace.space16;
''');
  }

  Future<void> test_allows_k_prefixed_non_token_constant() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_element
const _kMaxRetries = 3;
''');
  }
}

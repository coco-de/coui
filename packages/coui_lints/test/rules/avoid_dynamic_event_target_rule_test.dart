import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/avoid_dynamic_event_target_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDynamicEventTargetRuleTest);
  });
}

@reflectiveTest
class AvoidDynamicEventTargetRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDynamicEventTargetRule();
    super.setUp();
  }

  Future<void> test_flags_dynamic_event_parameter() async {
    final content = r'''
final Object handler = (dynamic event) {};
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('dynamic event'), 'dynamic event'.length),
    ]);
  }

  Future<void> test_flags_as_dynamic_property_access() async {
    final content = r'''
void f(Object event) {
  (event as dynamic).target;
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('event as dynamic'), 'event as dynamic'.length),
    ]);
  }

  Future<void> test_allows_typed_event_parameter() async {
    await assertNoDiagnostics(r'''
final Object handler = (Object event) {};
''');
  }

  Future<void> test_allows_as_dynamic_without_property_access() async {
    await assertNoDiagnostics(r'''
Object? f(Object event) => event as dynamic;
''');
  }
}

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/avoid_hardcoded_chrome_literal_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHardcodedChromeLiteralRuleTest);
  });
}

@reflectiveTest
class AvoidHardcodedChromeLiteralRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidHardcodedChromeLiteralRule();
    super.setUp();
  }

  Future<void> test_flags_border_radius_circular_literal() async {
    final content = r'''
class BorderRadius {
  const BorderRadius.circular(double radius);
}

const r = BorderRadius.circular(37);
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('37);'), '37'.length),
    ]);
  }

  Future<void> test_flags_border_all_width_literal() async {
    final content = r'''
class Border {
  const Border.all({double width = 1});
}

const b = Border.all(width: 42);
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('42);'), '42'.length),
    ]);
  }

  Future<void> test_flags_edge_insets_all_literal() async {
    final content = r'''
class EdgeInsets {
  const EdgeInsets.all(double value);
}

const p = EdgeInsets.all(53);
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('53);'), '53'.length),
    ]);
  }

  Future<void> test_allows_token_reference() async {
    await assertNoDiagnostics(r'''
class BorderRadius {
  const BorderRadius.circular(double radius);
}

class CoreRadius {
  static const radius8 = 8.0;
}

const r = BorderRadius.circular(CoreRadius.radius8);
''');
  }
}

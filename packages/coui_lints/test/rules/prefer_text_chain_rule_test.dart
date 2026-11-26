import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/prefer_text_chain_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferTextChainRuleTest);
  });
}

@reflectiveTest
class PreferTextChainRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferTextChainRule();
    super.setUp();
  }

  Future<void> test_flags_component_text() async {
    final content = r'''
class Component {
  const Component.text(String data);
}

const node = Component.text('hi');
''';
    await assertDiagnostics(content, [
      lint(
        content.indexOf("Component.text('hi')"),
        "Component.text('hi')".length,
      ),
    ]);
  }

  Future<void> test_allows_other_named_constructor() async {
    await assertNoDiagnostics(r'''
class Component {
  const Component.text(String data);
  const Component.element(String tag);
}

const node = Component.element('div');
''');
  }

  Future<void> test_allows_style_tag_payload_text() async {
    await assertNoDiagnostics(r'''
class Component {
  const Component.text(String data);
  const Component.element({String? tag, List<Component>? children});
}

const node = Component.element(
  tag: 'style',
  children: [Component.text('@keyframes x {}')],
);
''');
  }

  Future<void> test_flags_component_text_inside_div_element() async {
    final content = r'''
class Component {
  const Component.text(String data);
  const Component.element({String? tag, List<Component>? children});
}

const node = Component.element(
  tag: 'div',
  children: [Component.text('hi')],
);
''';
    await assertDiagnostics(content, [
      lint(
        content.indexOf("Component.text('hi')"),
        "Component.text('hi')".length,
      ),
    ]);
  }
}

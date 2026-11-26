import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/avoid_material_icon_glyph_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidMaterialIconGlyphRuleTest);
  });
}

@reflectiveTest
class AvoidMaterialIconGlyphRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMaterialIconGlyphRule();
    super.setUp();
  }

  Future<void> test_flags_icons_glyph() async {
    final content = r'''
class Icon {
  const Icon(Object? glyph);
}

class Icons {
  static const close = 1;
}

const icon = Icon(Icons.close);
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('Icons.close'), 'Icons.close'.length),
    ]);
  }

  Future<void> test_allows_non_icons_glyph() async {
    await assertNoDiagnostics(r'''
class Icon {
  const Icon(Object? glyph);
}

class RadixIcons {
  static const close = 1;
}

const icon = Icon(RadixIcons.close);
''');
  }

  Future<void> test_allows_icons_outside_icon_constructor() async {
    await assertNoDiagnostics(r'''
class Icons {
  static const close = 1;
}

class Badge {
  const Badge(Object? glyph);
}

const badge = Badge(Icons.close);
''');
  }
}

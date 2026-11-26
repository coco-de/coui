import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/avoid_framework_import_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFrameworkImportRuleTest);
  });
}

@reflectiveTest
class AvoidFrameworkImportRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('coui_flutter').addFile('lib/coui_flutter.dart', '');
    newPackage('coui_web').addFile('lib/coui_web.dart', '');
    newPackage('flutter').addFile('lib/material.dart', '');
    newPackage('jaspr').addFile('lib/jaspr.dart', '');
    rule = AvoidFrameworkImportRule();
    super.setUp();
  }

  Future<void> test_flags_material_alongside_coui_flutter_barrel() async {
    final content = r'''
// ignore_for_file: unused_import
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart';
''';
    await assertDiagnostics(content, [
      lint(
        content.indexOf("import 'package:flutter/material.dart';"),
        "import 'package:flutter/material.dart';".length,
      ),
    ]);
  }

  Future<void> test_flags_jaspr_alongside_coui_web_barrel() async {
    final content = r'''
// ignore_for_file: unused_import
import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart';
''';
    await assertDiagnostics(content, [
      lint(
        content.indexOf("import 'package:jaspr/jaspr.dart';"),
        "import 'package:jaspr/jaspr.dart';".length,
      ),
    ]);
  }

  Future<void> test_allows_coui_flutter_barrel_alone() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import
import 'package:coui_flutter/coui_flutter.dart';
''');
  }

  Future<void> test_allows_material_alone_without_coui_barrel() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import
import 'package:flutter/material.dart';
''');
  }

  Future<void> test_allows_prefixed_material_alongside_barrel() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
''');
  }

  Future<void> test_allows_show_narrowed_material_alongside_barrel() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import, undefined_shown_name
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' show SelectableText;
''');
  }
}

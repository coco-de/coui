import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/prefer_stacks_and_position_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferStacksAndPositionRuleTest);
  });
}

@reflectiveTest
class PreferStacksAndPositionRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('coui_flutter').addFile('lib/coui_flutter.dart', '');
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Stack {
  const Stack({List<Object?>? children});
}

class Positioned {
  const Positioned({double? top, Object? child});
  const Positioned.fill({Object? child});
}
''');
    rule = PreferStacksAndPositionRule();
    super.setUp();
  }

  Future<void> test_flags_stack_in_coui_flutter_consumer() async {
    final content = r'''
// ignore_for_file: unused_import
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';

void f() {
  Stack(children: const []);
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('Stack('), 'Stack'.length),
    ]);
  }

  Future<void> test_flags_positioned_in_coui_flutter_consumer() async {
    final content = r'''
// ignore_for_file: unused_import
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';

void f() {
  Positioned(top: 0);
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('Positioned('), 'Positioned'.length),
    ]);
  }

  Future<void> test_allows_stack_without_coui_flutter_barrel() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f() {
  Stack(children: const []);
}
''');
  }

  Future<void> test_allows_stack_inside_stacks_implementation_file() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';

class Stacks {
  const Stacks();

  Object build() => Stack(children: const []);
}
''');
  }

  Future<void>
  test_allows_positioned_inside_position_implementation_file() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';

class Position {
  const Position();

  Object build() => Positioned(top: 0);
}
''');
  }
}

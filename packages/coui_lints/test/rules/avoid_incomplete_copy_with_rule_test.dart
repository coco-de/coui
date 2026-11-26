import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/avoid_incomplete_copy_with_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidIncompleteCopyWithRuleTest);
  });
}

@reflectiveTest
class AvoidIncompleteCopyWithRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidIncompleteCopyWithRule();
    super.setUp();
  }

  Future<void> test_flags_missing_field() async {
    // `blur` is neither accepted nor read, so the rebuilt constructor
    // resets it to null — the caller changed `opacity` and lost `blur`.
    final content = r'''
class Token {
  const Token({this.opacity, this.blur});
  final double? opacity;
  final double? blur;
  Token copyWith({double? opacity}) => Token(opacity: opacity ?? this.opacity);
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('copyWith'), 'copyWith'.length),
    ]);
  }

  Future<void> test_flags_every_missing_field_in_one_report() async {
    final content = r'''
class Token {
  const Token({this.a, this.b, this.c});
  final int? a;
  final int? b;
  final int? c;
  Token copyWith({int? a}) => Token(a: a ?? this.a);
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('copyWith'), 'copyWith'.length),
    ]);
  }

  Future<void> test_allows_field_carried_without_a_parameter() async {
    await assertNoDiagnostics(r'''
class Token {
  const Token({this.opacity, this.blur});
  final double? opacity;
  final double? blur;
  Token copyWith({double? opacity}) =>
      Token(opacity: opacity ?? this.opacity, blur: blur);
}
''');
  }

  Future<void> test_allows_complete_copy_with() async {
    await assertNoDiagnostics(r'''
class Token {
  const Token({this.opacity, this.blur});
  final double? opacity;
  final double? blur;
  Token copyWith({double? opacity, double? blur}) => Token(
    opacity: opacity ?? this.opacity,
    blur: blur ?? this.blur,
  );
}
''');
  }

  Future<void> test_skips_static_private_and_initialised_fields() async {
    await assertNoDiagnostics(r'''
class Token {
  Token({this.opacity});
  static const double defaultOpacity = 1;
  final double? opacity;
  final int _cache = 0;
  final List<int> history = [];
  Token copyWith({double? opacity}) => Token(opacity: opacity ?? this.opacity);
  int get cache => _cache;
}
''');
  }

  Future<void> test_ignores_class_without_copy_with() async {
    await assertNoDiagnostics(r'''
class Token {
  const Token({this.opacity, this.blur});
  final double? opacity;
  final double? blur;
}
''');
  }

  Future<void> test_ignores_static_copy_with() async {
    await assertNoDiagnostics(r'''
class Token {
  const Token({this.opacity, this.blur});
  final double? opacity;
  final double? blur;
  static Token copyWith(Token t) => t;
}
''');
  }

  Future<void> test_a_shadowing_parameter_is_not_a_field_read() async {
    // The positional `opacity` shadows the field: the body reads the
    // parameter, so a null argument resets the field.
    final content = r'''
class Token {
  const Token(this.opacity);
  final double? opacity;
  Token copyWith([double? opacity]) => Token(opacity);
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('copyWith'), 'copyWith'.length),
    ]);
  }

  Future<void> test_this_access_sees_through_a_shadow() async {
    await assertNoDiagnostics(r'''
class Token {
  const Token(this.opacity);
  final double? opacity;
  Token copyWith([double? opacity]) => Token(opacity ?? this.opacity);
}
''');
  }

  Future<void> test_another_objects_member_is_not_a_read() async {
    final content = r'''
class Token {
  const Token({this.opacity, this.blur});
  final double? opacity;
  final double? blur;
  Token copyWith({double? opacity, Token? from}) =>
      Token(opacity: opacity ?? this.opacity, blur: from?.blur);
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('copyWith'), 'copyWith'.length),
    ]);
  }

  Future<void> test_allows_field_preserved_by_reading_it() async {
    await assertNoDiagnostics(r'''
class Insets {
  const Insets.physical(this.left) : isDirectional = false;
  const Insets.directional(this.left) : isDirectional = true;
  final double left;
  final bool isDirectional;
  Insets copyWith({double? left}) => isDirectional
      ? Insets.directional(left ?? this.left)
      : Insets.physical(left ?? this.left);
}
''');
  }

  Future<void> test_a_named_argument_label_is_not_a_read() async {
    final content = r'''
class Field {
  const Field({this.variant, this.hint});
  final int? variant;
  final String? hint;
  Field copyWith({String? hint}) => Field(variant: null, hint: hint ?? this.hint);
}
''';
    await assertDiagnostics(content, [
      lint(content.indexOf('copyWith'), 'copyWith'.length),
    ]);
  }

  Future<void> test_skips_abstract_copy_with() async {
    await assertNoDiagnostics(r'''
abstract class Base {
  const Base({this.tag, this.id});
  final String? tag;
  final String? id;
  Base copyWith({String? id});
}
''');
  }
}

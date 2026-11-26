// `test_reflective_loader` finds a test by its `test_` prefix, so the
// methods below cannot be lowerCamelCase.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:coui_lints/src/rules/pass_theme_geometry_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PassThemeGeometryRuleTest);
  });
}

/// The shapes a conversion and its caller take in `coui_flutter`, reduced
/// to what the rule reads: the parameter's name, its type and whether it
/// is optional and named.
const _kPreamble = '''
class CoreSurfaceGeometryConstraint {
  const CoreSurfaceGeometryConstraint();
}

class CoreEdgeInsets {
  const CoreEdgeInsets();
}

extension CoreEdgeInsetsToFlutter on CoreEdgeInsets {
  double toValue({CoreSurfaceGeometryConstraint? geometry}) => 0;
  double toGeometry({CoreSurfaceGeometryConstraint? geometry}) => 0;
}

const geometry = CoreSurfaceGeometryConstraint();
''';

@reflectiveTest
class PassThemeGeometryRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PassThemeGeometryRule();
    super.setUp();
  }

  Future<void> test_flags_a_conversion_called_without_geometry() async {
    // The density never reaches this padding: the call renders the
    // authored value.
    const content =
        '$_kPreamble'
        '''
double f(CoreEdgeInsets insets) => insets.toValue();
''';
    final call = content.indexOf('toValue()');
    await assertDiagnostics(content, [lint(call, 'toValue'.length)]);
  }

  Future<void> test_flags_a_null_aware_call() async {
    const content =
        '$_kPreamble'
        '''
double? f(CoreEdgeInsets? insets) => insets?.toGeometry();
''';
    final call = content.indexOf('toGeometry()');
    await assertDiagnostics(content, [lint(call, 'toGeometry'.length)]);
  }

  Future<void> test_flags_a_top_level_function() async {
    const content = '''
class CoreSurfaceGeometryConstraint {
  const CoreSurfaceGeometryConstraint();
}

double bend(double px, {CoreSurfaceGeometryConstraint? geometry}) => px;

double f() => bend(16);
''';
    final call = content.indexOf('bend(16)');
    await assertDiagnostics(content, [lint(call, 'bend'.length)]);
  }

  Future<void> test_allows_a_conversion_given_the_geometry() async {
    await assertNoDiagnostics(
      '$_kPreamble'
      '''
double f(CoreEdgeInsets insets) =>
    insets.toValue(geometry: geometry) +
    insets.toGeometry(geometry: geometry);
''',
    );
  }

  Future<void> test_ignores_copy_with() async {
    // `copyWith(geometry:)` replaces a field; leaving it out keeps the
    // field, which is the point of a copy.
    await assertNoDiagnostics('''
class CoreSurfaceGeometryConstraint {
  const CoreSurfaceGeometryConstraint();
}

class Recipe {
  const Recipe({this.geometry, this.name});
  final CoreSurfaceGeometryConstraint? geometry;
  final String? name;

  Recipe copyWith({CoreSurfaceGeometryConstraint? geometry, String? name}) =>
      Recipe(geometry: geometry ?? this.geometry, name: name ?? this.name);
}

Recipe f(Recipe r) => r.copyWith(name: 'x');
''');
  }

  Future<void> test_ignores_a_required_geometry() async {
    // The compiler already makes this one impossible to forget.
    await assertNoDiagnostics('''
class CoreSurfaceGeometryConstraint {
  const CoreSurfaceGeometryConstraint();
}

double bend(double px, {required CoreSurfaceGeometryConstraint geometry}) =>
    px;

double f() => bend(16, geometry: const CoreSurfaceGeometryConstraint());
''');
  }

  Future<void> test_ignores_a_geometry_of_another_type() async {
    await assertNoDiagnostics('''
class Rect {
  const Rect();
}

double place(double px, {Rect? geometry}) => px;

double f() => place(16);
''');
  }

  Future<void> test_ignores_a_positional_geometry() async {
    await assertNoDiagnostics('''
class CoreSurfaceGeometryConstraint {
  const CoreSurfaceGeometryConstraint();
}

double bend(double px, [CoreSurfaceGeometryConstraint? geometry]) => px;

double f() => bend(16);
''');
  }
}

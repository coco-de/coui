import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

const _kGeometryParameter = 'geometry';
const _kGeometryType = 'CoreSurfaceGeometryConstraint';

/// Flags a call that leaves out an optional `geometry` argument of type
/// `CoreSurfaceGeometryConstraint?`.
///
/// Flutter has no runtime indirection between a resolver and a painted
/// value — no equivalent of the CSS variable the Web side re-points — so a
/// theme axis that bends geometry (a surface style, a density) reaches a
/// value only where a Core value becomes a Flutter one, by being handed the
/// theme's `geometry`. A conversion that takes it as a *required*
/// parameter is enforced by the compiler. One that takes it as an
/// *optional* parameter does so because it is public API that apps call on
/// their own values, and making it required would break them without a
/// deprecation window — which leaves "someone forgot" to this rule. A call
/// without the argument renders the authored value and ignores the axis,
/// with nothing on screen to say so until the axis is switched.
///
/// A `copyWith` is not checked: its `geometry` names a field to replace,
/// and leaving it out keeps the field — the opposite of a conversion that
/// drops the theme's geometry.
///
/// See `.claude/rules/core/theme-axis-composition.md` ("재지정 지점은
/// 강제되어야 한다").
class PassThemeGeometryRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  PassThemeGeometryRule()
    : super(
        name: 'pass_theme_geometry',
        description:
            "A call that can take the theme's geometry should pass it, so "
            'the geometry axes (surface style, density) reach the value.',
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'pass_theme_geometry',
    "'{0}' takes the theme's geometry, but this call leaves it out — the "
        'value renders as authored and ignores the theme density.',
    correctionMessage:
        "Pass 'geometry: theme.geometry' (the resolver's "
        '`Theme.of(context).geometry`).',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry
      ..addMethodInvocation(this, visitor)
      ..addFunctionExpressionInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PassThemeGeometryRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'copyWith') return;
    _check(node, node.methodName);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _check(node, node.function);
  }

  void _check(InvocationExpression node, AstNode reportAt) {
    // The invoked type rather than the element: it covers a method, an
    // extension member, a top-level function and a function-typed value
    // alike, and it is what the call is checked against.
    final type = node.staticInvokeType;
    if (type is! FunctionType) return;
    if (!type.formalParameters.any(_isOptionalGeometry)) return;

    final passes = node.argumentList.arguments.any(
      (argument) =>
          argument is NamedArgument &&
          argument.name.lexeme == _kGeometryParameter,
    );
    if (passes) return;

    final _ = rule.reportAtNode(reportAt, arguments: [reportAt.toSource()]);
  }

  bool _isOptionalGeometry(FormalParameterElement parameter) {
    if (!parameter.isOptionalNamed) return false;
    if (parameter.name != _kGeometryParameter) return false;

    final type = parameter.type;
    return type.element?.name == _kGeometryType &&
        type.nullabilitySuffix == NullabilitySuffix.question;
  }
}

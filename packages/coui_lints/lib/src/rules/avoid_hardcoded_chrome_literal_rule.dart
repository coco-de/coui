import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const _kEdgeInsetsConstructors = {
  'all',
  'symmetric',
  'only',
  'fromLTRB',
};

/// Flags a raw numeric literal in `BorderRadius.circular(...)`,
/// `Border.all(width: ...)`, or `EdgeInsets.*(...)` in favor of a
/// domain-typed Core default.
///
/// See `.claude/rules/core/design-tokens.md`, "카테고리별 Core 토큰 매핑", and the
/// Phase 5 CI guard in `scripts/guards/tokens/check_design_tokens.sh`.
class AvoidHardcodedChromeLiteralRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  AvoidHardcodedChromeLiteralRule()
    : super(
        name: 'avoid_hardcoded_chrome_literal',
        description:
            'BorderRadius/Border/EdgeInsets constructors should reference a '
            'Core token, not a raw numeric literal.',
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'avoid_hardcoded_chrome_literal',
    "Avoid a raw numeric literal in '{0}'; use a domain-typed Core default "
        '(e.g. CoreRadius.radius8 / CoreStrokeWidth.stroke1 / '
        'CoreSpace.space16) so this chrome value stays tokenized and '
        'overridable.',
    correctionMessage:
        'Replace the literal with the matching CoreXxxStyle.default* field '
        'for this component.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidHardcodedChromeLiteralRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.name.lexeme;
    final ctorName = constructorName.name?.name;

    if (typeName == 'BorderRadius' && ctorName == 'circular') {
      _reportLiterals(node, 'BorderRadius.circular');
    } else if (typeName == 'Border' && ctorName == 'all') {
      _reportNamedLiteral(node, 'width', 'Border.all');
    } else if (typeName == 'EdgeInsets' &&
        ctorName != null &&
        _kEdgeInsetsConstructors.contains(ctorName)) {
      _reportLiterals(node, 'EdgeInsets.$ctorName');
    }
  }

  void _reportLiterals(InstanceCreationExpression node, String label) {
    for (final argument in node.argumentList.arguments) {
      final expression = argument is NamedArgument
          ? argument.argumentExpression
          : argument;
      if (expression is IntegerLiteral || expression is DoubleLiteral) {
        final _ = rule.reportAtNode(expression, arguments: [label]);
      }
    }
  }

  void _reportNamedLiteral(
    InstanceCreationExpression node,
    String argumentName,
    String label,
  ) {
    for (final argument in node.argumentList.arguments) {
      if (argument is! NamedArgument) continue;
      if (argument.name.lexeme != argumentName) continue;
      final expression = argument.argumentExpression;
      if (expression is IntegerLiteral || expression is DoubleLiteral) {
        final _ = rule.reportAtNode(expression, arguments: [label]);
      }
    }
  }
}

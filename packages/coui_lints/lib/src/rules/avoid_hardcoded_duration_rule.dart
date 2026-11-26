import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:coui_lints/src/utils.dart';

const _kDurationFieldNames = {'milliseconds', 'seconds'};

/// Flags a raw `milliseconds`/`seconds` literal in `Duration(...)` in favor
/// of a `CoreDuration` token.
///
/// See `.claude/rules/core/design-tokens.md`, "애니메이션 토큰 — CoreDuration
/// 단일 소스", and the Phase 1 CI guard in
/// `scripts/guards/tokens/check_design_tokens.sh`.
class AvoidHardcodedDurationRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  AvoidHardcodedDurationRule()
    : super(
        name: 'avoid_hardcoded_duration',
        description:
            'Duration(...) literals should reference a CoreDuration token, '
            'not a raw millisecond/second number.',
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'avoid_hardcoded_duration',
    "Avoid a raw '{0}: {1}' literal in Duration(...); reference a "
        'CoreDuration token (e.g. CoreDuration.normal) so Flutter and Web '
        'share one animation-timing source of truth.',
    correctionMessage:
        "Replace the literal with 'CoreDuration.*', or extract a local "
        "'const _kXxx = Duration(...)' constant if this value is reused.",
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

  final AvoidHardcodedDurationRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.type.name.lexeme != 'Duration') return;
    if (constructorName.name != null) return;
    if (isWithinKPrefixedConstant(node)) return;

    for (final argument in node.argumentList.arguments) {
      if (argument is! NamedArgument) continue;
      if (!_kDurationFieldNames.contains(argument.name.lexeme)) continue;
      final value = argument.argumentExpression;
      if (value is IntegerLiteral) {
        final _ = rule.reportAtNode(
          argument,
          arguments: [argument.name.lexeme, value.literal.lexeme],
        );
      }
    }
  }
}

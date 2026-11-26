import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:coui_lints/src/utils.dart';

final _kPrefixedConstant = RegExp('^_k[A-Z]');

/// Flags a private `_k`-prefixed constant whose initializer directly
/// aliases a Core token namespace member (e.g.
/// `const _kDefaultPadding = CoreSpace.space16;`).
///
/// A second, file-local copy of a default can silently diverge from the
/// component's own `CoreXxxStyle.default*`, which is supposed to be the
/// single source of truth shared by Flutter and Web. See
/// `.claude/rules/resolver/resolver-pattern.md`, "별도 Defaults holder /
/// 파일 / phantom generic 금지".
class AvoidLocalTokenConstantRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  AvoidLocalTokenConstantRule()
    : super(
        name: 'avoid_local_token_constant',
        description:
            "A private '_k'-prefixed constant should not directly alias a "
            'Core token namespace member — that default belongs on the '
            "component's CoreXxxStyle.",
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'avoid_local_token_constant',
    "Avoid a local '{0}' constant that just aliases a Core token ('{1}'); "
        'a second copy of the same default can silently diverge from the '
        'one Flutter and Web are supposed to share.',
    correctionMessage:
        "Move this default into the component's CoreXxxStyle as a named "
        "'static const default*' field, and reference it directly.",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidLocalTokenConstantRule rule;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final list = node.parent;
    if (list is! VariableDeclarationList || !list.isConst) return;

    final name = node.name.lexeme;
    if (!_kPrefixedConstant.hasMatch(name)) return;

    final initializer = node.initializer;
    if (initializer is! PrefixedIdentifier) return;
    if (!kCoreTokenNamespaces.contains(initializer.prefix.name)) return;

    final _ = rule.reportAtNode(
      node,
      arguments: [name, initializer.toSource()],
    );
  }
}

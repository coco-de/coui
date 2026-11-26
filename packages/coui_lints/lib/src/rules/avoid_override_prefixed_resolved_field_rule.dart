import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

final _resolvedClassName = RegExp('^Resolved[A-Z]');
final _overridePrefixedField = RegExp('^override[A-Z]');

/// Flags an `override`-prefixed field on a `Resolved*` class.
///
/// A `Resolved*` field already stores the final, fallback-applied value —
/// the `override` prefix implies an unresolved state that no longer exists
/// at that layer. See `.claude/rules/code-style/naming.md`, "resolved 필드
/// — override* prefix 금지".
class AvoidOverridePrefixedResolvedFieldRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  AvoidOverridePrefixedResolvedFieldRule()
    : super(
        name: 'avoid_override_prefixed_resolved_field',
        description:
            "Resolved* class fields should not carry an 'override' prefix.",
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'avoid_override_prefixed_resolved_field',
    "Avoid the 'override' prefix on Resolved field '{0}'; a Resolved* "
        'field already stores the final, fallback-applied value, so the '
        'prefix implies an unresolved state that no longer exists here.',
    correctionMessage:
        "Drop the 'override' prefix (e.g. 'overrideBackgroundColor' -> "
        "'backgroundColor').",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidOverridePrefixedResolvedFieldRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!_resolvedClassName.hasMatch(node.namePart.typeName.lexeme)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is! FieldDeclaration) continue;
      for (final field in member.fields.variables) {
        final name = field.name.lexeme;
        if (_overridePrefixedField.hasMatch(name)) {
          final _ = rule.reportAtNode(field, arguments: [name]);
        }
      }
    }
  }
}

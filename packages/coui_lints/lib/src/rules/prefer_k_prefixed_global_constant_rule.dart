import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

final _kPrefixed = RegExp('^_?k[A-Z0-9]');

/// Flags a top-level `const` whose name does not start with `k` / `_k`.
///
/// The prefix is how a reader tells a compile-time constant from a
/// variable at the use site, where the declaration is out of sight.
///
/// An annotation constant is exempt: `const immutable = Immutable();` is
/// the `package:meta` idiom — a lower-case alias of its own class, used as
/// `@immutable` — and it is named for the annotation, not the constant.
/// The exemption is exactly that shape, so a constant cannot claim it by
/// accident.
///
/// See `.claude/rules/code-style/naming.md` (전역 상수 `k` 접두).
class PreferKPrefixedGlobalConstantRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  PreferKPrefixedGlobalConstantRule()
    : super(
        name: 'prefer_k_prefixed_global_constant',
        description: "Top-level constants should start with 'k'.",
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'prefer_k_prefixed_global_constant',
    "The top-level constant '{0}' should start with 'k'.",
    correctionMessage: "Rename it to '{1}'.",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferKPrefixedGlobalConstantRule rule;

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (!node.variables.isConst) return;
    for (final variable in node.variables.variables) {
      final name = variable.name.lexeme;
      if (_kPrefixed.hasMatch(name)) continue;
      if (_isAnnotationConstant(name, variable.initializer)) continue;

      final private = name.startsWith('_');
      final bare = private ? name.substring(1) : name;
      final suggestion =
          '${private ? '_' : ''}k${bare[0].toUpperCase()}${bare.substring(1)}';
      final _ = rule.reportAtToken(
        variable.name,
        arguments: [name, suggestion],
      );
    }
  }

  /// `const immutable = Immutable();` — a lower-case alias of its own class.
  bool _isAnnotationConstant(String name, Expression? initializer) {
    if (initializer is! InstanceCreationExpression) return false;
    final bare = name.startsWith('_') ? name.substring(1) : name;
    if (bare.isEmpty) return false;
    final typeName = initializer.constructorName.type.name.lexeme;
    return typeName == '${bare[0].toUpperCase()}${bare.substring(1)}';
  }
}

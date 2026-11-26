import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// URIs of the CoUI barrel imports. A file that imports one of these already
/// re-exports the framework types it needs — see
/// `.claude/rules/cross-platform/api.md`, rule "Import".
const _kCouiBarrelUris = {
  'package:coui_flutter/coui_flutter.dart',
  'package:coui_web/coui_web.dart',
};

/// Framework imports that become redundant — and risk making bare CoUI
/// names like `Button`/`Card` ambiguous — once a CoUI barrel is imported.
const _kFrameworkUris = {
  'package:flutter/material.dart',
  'package:flutter/widgets.dart',
  'package:flutter/cupertino.dart',
  'package:jaspr/jaspr.dart',
};

/// Flags an unprefixed, unnarrowed framework import (`material.dart`,
/// `jaspr.dart`, ...) alongside a CoUI barrel import in the same library.
///
/// A prefixed (`as m`) or `show`-narrowed framework import is allowed: it
/// injects no bare framework names into the namespace, so it cannot make
/// bare CoUI names ambiguous — and it is exactly how a file deliberately
/// reaches for a framework-only symbol the barrel does not re-export.
class AvoidFrameworkImportRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  AvoidFrameworkImportRule()
    : super(
        name: 'avoid_framework_import',
        description:
            'A file that imports a CoUI barrel should not also import the '
            'underlying framework directly without a prefix or a show '
            'combinator.',
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'avoid_framework_import',
    "Avoid importing '{0}' alongside the CoUI barrel import '{1}'. CoUI "
        're-exports the framework types you need, and a direct framework '
        'import can make bare CoUI names ambiguous with framework widgets '
        'of the same name.',
    correctionMessage:
        'Remove this import, or — if a framework-only symbol is genuinely '
        "needed — narrow it with a prefix ('as m') or a 'show' combinator.",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidFrameworkImportRule rule;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null || !_kFrameworkUris.contains(uri)) return;

    // Prefixed / show-narrowed imports inject no bare framework names, so
    // the ambiguity hazard this rule exists for cannot occur.
    if (node.prefix != null) return;
    if (node.combinators.any(
      (combinator) => combinator is ShowCombinator,
    )) {
      return;
    }

    final unit = node.parent;
    if (unit is! CompilationUnit) return;

    for (final directive in unit.directives.whereType<ImportDirective>()) {
      final siblingUri = directive.uri.stringValue;
      if (siblingUri != null && _kCouiBarrelUris.contains(siblingUri)) {
        final _ = rule.reportAtNode(node, arguments: [uri, siblingUri]);
        return;
      }
    }
  }
}

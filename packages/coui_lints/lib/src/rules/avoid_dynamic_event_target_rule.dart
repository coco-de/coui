import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Flags `(dynamic event)` parameters and `(x as dynamic).y` property
/// access in Web event handlers.
///
/// Release (dart2js-minified) builds can mangle dynamic member names,
/// desyncing the handler at runtime — a bug class that only shows up after
/// a release build, never in `jaspr serve`. See
/// `.claude/rules/web/web-specifics.md`, "Web 이벤트 핸들러 — dart2js
/// minification 함정".
class AvoidDynamicEventTargetRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  AvoidDynamicEventTargetRule()
    : super(
        name: 'avoid_dynamic_event_target',
        description:
            "Web event handlers should not use '(dynamic event)' "
            "parameters or 'as dynamic' casts to read event properties.",
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'avoid_dynamic_event_target',
    'Avoid dynamic dispatch on a Web event handler ({0}); release '
        '(dart2js-minified) builds can mangle dynamic member names and '
        "desync the handler. Use an 'EventHandlers.createXxxEventHandler' "
        'helper from ui_events.dart instead.',
    correctionMessage:
        "Use the matching 'EventHandlers.createXxxEventHandler' helper.",
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
      ..addRegularFormalParameter(this, visitor)
      ..addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDynamicEventTargetRule rule;

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    // A function-typed parameter (`R event(int x)`) is a regular parameter
    // too, and its `type` is the return type: only `dynamic event` counts.
    if (node.functionTypedSuffix != null) return;

    final type = node.type;
    if (node.name?.lexeme != 'event' || type is! NamedType) return;
    if (type.name.lexeme == 'dynamic') {
      final _ = rule.reportAtNode(
        node,
        arguments: ["'dynamic event' parameter"],
      );
    }
  }

  @override
  void visitAsExpression(AsExpression node) {
    final type = node.type;
    if (type is! NamedType || type.name.lexeme != 'dynamic') return;

    var parent = node.parent;
    if (parent is ParenthesizedExpression) parent = parent.parent;

    if (parent is PropertyAccess) {
      final _ = rule.reportAtNode(
        node,
        arguments: ["property access on an 'as dynamic' cast"],
      );
    }
  }
}

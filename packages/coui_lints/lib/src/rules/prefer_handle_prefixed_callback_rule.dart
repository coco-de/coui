import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

final _callbackParameter = RegExp('^on[A-Z]');
final _handlerName = RegExp('^_?handle[A-Z]');

/// Flags a method or function torn off into an `on*` callback whose name
/// does not start with `handle` (or `_handle`).
///
/// The `handle` stem is how a reader finds every place a component reacts
/// to input: the callback parameter says *when* (`onTap`), the method says
/// it is a *reaction* (`_handleTap`). Visibility is ordinary Dart — a
/// handler is private when nothing outside needs it.
///
/// Only a tear-off of a declared method or function is checked. Passing a
/// closure, or forwarding a callback held in a field or parameter
/// (`onTap: widget.onTap`, `onTap: onTap`), names nothing new, so there is
/// nothing to check.
///
/// See `.claude/rules/code-style/naming.md` (handler 함수명).
class PreferHandlePrefixedCallbackRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  PreferHandlePrefixedCallbackRule()
    : super(
        name: 'prefer_handle_prefixed_callback',
        description:
            "A method torn off into an 'on*' callback should be named "
            "'handle*'.",
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'prefer_handle_prefixed_callback',
    "'{0}' is passed as the '{1}' callback; name it '{2}'.",
    correctionMessage:
        "Rename the method so it starts with 'handle' (or '_handle').",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addArgumentList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferHandlePrefixedCallbackRule rule;

  @override
  void visitArgumentList(ArgumentList node) {
    for (final argument in node.arguments) {
      final parameterName = argument.correspondingParameter?.name;
      if (parameterName == null ||
          !_callbackParameter.hasMatch(parameterName)) {
        continue;
      }

      // An argument is the expression itself, or a `name: expression` pair.
      final Expression expression;
      if (argument is NamedArgument) {
        expression = argument.argumentExpression;
      } else if (argument is Expression) {
        expression = argument;
      } else {
        continue;
      }
      final value = expression.unParenthesized;
      if (value is! SimpleIdentifier) continue;

      final element = value.element;
      final isTearOff =
          element is MethodElement ||
          element is TopLevelFunctionElement ||
          element is LocalFunctionElement;
      if (!isTearOff) continue;

      final name = value.name;
      if (_handlerName.hasMatch(name)) continue;

      final _ = rule.reportAtNode(
        value,
        arguments: [name, parameterName, _suggest(name)],
      );
    }
  }

  /// Keeps the method's own meaning: `_goToPrev` → `_handleGoToPrev`,
  /// `_onTick` → `_handleTick`. Deriving it from the parameter instead would
  /// hand two different methods fed to `onTap` the same name.
  String _suggest(String name) {
    final private = name.startsWith('_');
    var bare = private ? name.substring(1) : name;
    if (_callbackParameter.hasMatch(bare)) bare = bare.substring('on'.length);
    final capitalised = '${bare[0].toUpperCase()}${bare.substring(1)}';
    return '${private ? '_' : ''}handle$capitalised';
  }
}

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Path fragments of the documented primitive boundaries where
/// `Component.text(...)` is the correct API — the chain base
/// implementation itself, mono/code blocks whose typography inheritance is
/// meaningless, and native-input internals. See
/// `.claude/rules/web/web-specifics.md`, "`Component.text(` 정당 예외".
const _kPrimitiveBoundaryPathFragments = {
  '/components/text/',
  '/components/display/code_diff/',
  '/components/display/code_snippet/',
  '/components/display/mockup_code/',
  '/components/display/kbd/',
  '/components/control/command/',
  '/components/form/text_area/',
  '/components/form/text_field/',
};

/// Element tags whose text child is raw CSS/JS payload, not user-visible
/// text — the chain API does not apply inside them.
const _kRawTextElementTags = {'style', 'script'};

/// Flags `Component.text(...)` in favor of the CoUI `Text(...)` chain API.
///
/// The documented primitive boundaries (chain base implementation,
/// mono/code blocks, native-input internals, `<style>`/`<script>` payload
/// text) are exempt — see `.claude/rules/cross-platform/api.md`, "Text 체인
/// API", and `.claude/rules/web/web-specifics.md`, "CoUI `Text()` 사용 — raw
/// Jaspr `text()` 금지".
class PreferTextChainRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  PreferTextChainRule()
    : super(
        name: 'prefer_text_chain',
        description:
            "Text nodes should use CoUI's 'Text(...)' chain API instead of "
            "raw 'Component.text(...)'.",
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'prefer_text_chain',
    "Avoid 'Component.text(...)'; use CoUI's 'Text(...)' chain API (e.g. "
        "Text('...').bodyMedium.onSurface) so typography and color are "
        'inherited consistently on Flutter and Web.',
    correctionMessage:
        "Replace with 'Text(...)'. Documented primitive boundaries "
        '(see web-specifics.md) are exempt automatically.',
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

  final PreferTextChainRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.type.name.lexeme != 'Component') return;
    if (constructorName.name?.name != 'text') return;
    if (_isAtPrimitiveBoundary(node)) return;
    if (_isRawTextElementPayload(node)) return;
    final _ = rule.reportAtNode(node);
  }

  /// Whether the enclosing file is one of the documented primitive
  /// boundaries where `Component.text` is the correct API.
  bool _isAtPrimitiveBoundary(AstNode node) {
    final root = node.root;
    if (root is! CompilationUnit) return false;
    final path = root.declaredFragment?.source.fullName;
    if (path == null) return false;
    return _kPrimitiveBoundaryPathFragments.any(path.contains);
  }

  /// Whether [node] is the text payload of a `Component.element` whose tag
  /// is `<style>`/`<script>` — raw CSS/JS, not a user-visible text node.
  bool _isRawTextElementPayload(AstNode node) {
    for (
      var ancestor = node.parent;
      ancestor != null;
      ancestor = ancestor.parent
    ) {
      if (ancestor is! InstanceCreationExpression) continue;
      final constructorName = ancestor.constructorName;
      if (constructorName.type.name.lexeme != 'Component') continue;
      if (constructorName.name?.name != 'element') continue;
      for (final argument in ancestor.argumentList.arguments) {
        if (argument is! NamedArgument) continue;
        if (argument.name.lexeme != 'tag') continue;
        final tag = argument.argumentExpression;
        if (tag is SimpleStringLiteral &&
            _kRawTextElementTags.contains(tag.value)) {
          return true;
        }
      }
    }
    return false;
  }
}

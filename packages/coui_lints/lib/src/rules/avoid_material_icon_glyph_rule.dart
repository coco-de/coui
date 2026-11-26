import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Flags `Icon(Icons.xxx)` — Flutter's Material icon font — in favor of
/// the CoUI icon catalogue (`LucideIcons`).
///
/// See `.claude/rules/code-style/naming.md`, "통일 컴포넌트 / 아이콘 클래스명 사용 의무".
class AvoidMaterialIconGlyphRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  AvoidMaterialIconGlyphRule()
    : super(
        name: 'avoid_material_icon_glyph',
        description:
            "Avoid Flutter's Material 'Icons' font glyphs; CoUI icons use "
            'RadixIcons/LucideIcons/BootstrapIcons/HeroIcons.',
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'avoid_material_icon_glyph',
    "Avoid 'Icons.{0}' (the Material icon font) as an Icon glyph; use "
        'the CoUI icon catalogue (LucideIcons).',
    correctionMessage:
        "Replace 'Icons.{0}' with the matching glyph from LucideIcons.",
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

  final AvoidMaterialIconGlyphRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme != 'Icon') return;

    for (final argument in node.argumentList.arguments) {
      final expression = argument is NamedArgument
          ? argument.argumentExpression
          : argument;
      if (expression is PrefixedIdentifier &&
          expression.prefix.name == 'Icons') {
        final _ = rule.reportAtNode(
          expression,
          arguments: [expression.identifier.name],
        );
      }
    }
  }
}

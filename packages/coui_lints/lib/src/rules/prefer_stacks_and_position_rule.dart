import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

const _kFlutterLibraryPrefix = 'package:flutter/';
const _kCouiFlutterBarrelUri = 'package:coui_flutter/coui_flutter.dart';

/// Maps a raw Flutter widget name to the CoUI unified replacement a
/// consumer file (one that already imports the CoUI barrel) should use
/// instead. See `.claude/rules/code-style/naming.md`, "통일 컴포넌트 사용 의무".
const _kReplacements = {
  'Stack': 'Stacks',
  'Positioned': 'Position',
};

/// Flags raw Flutter `Stack`/`Positioned` construction in a file that
/// already imports the CoUI Flutter barrel.
///
/// The file that *implements* a replacement (declares the `Stacks` /
/// `Position` class itself) is exempt — the unified widget necessarily
/// renders through the raw Flutter widget it wraps.
class PreferStacksAndPositionRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  PreferStacksAndPositionRule()
    : super(
        name: 'prefer_stacks_and_position',
        description:
            "Prefer CoUI's 'Stacks'/'Position' over raw Flutter "
            "'Stack'/'Positioned' in files that already use the CoUI "
            'barrel.',
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'prefer_stacks_and_position',
    "Avoid Flutter's '{0}' in a file that already imports the CoUI "
        "barrel; use CoUI's '{1}' instead so the same code reads the same "
        'on Web.',
    correctionMessage: "Replace with '{1}'.",
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

  final PreferStacksAndPositionRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type;
    final replacement = _kReplacements[type.name.lexeme];
    if (replacement == null) return;

    final library = type.element?.library;
    if (library == null ||
        !library.identifier.startsWith(_kFlutterLibraryPrefix)) {
      return;
    }

    if (!_importsCouiFlutterBarrel(node.root)) return;
    if (_declaresClass(node.root, replacement)) return;

    final _ = rule.reportAtNode(
      node.constructorName,
      arguments: [type.name.lexeme, replacement],
    );
  }

  bool _importsCouiFlutterBarrel(AstNode root) {
    if (root is! CompilationUnit) return false;
    for (final directive in root.directives.whereType<ImportDirective>()) {
      if (directive.uri.stringValue == _kCouiFlutterBarrelUri) return true;
    }
    return false;
  }

  /// Whether the enclosing file declares [name] itself — i.e. it is the
  /// unified widget's own implementation, which must use the raw Flutter
  /// widget to render.
  bool _declaresClass(AstNode root, String name) {
    if (root is! CompilationUnit) return false;
    return root.declarations.whereType<ClassDeclaration>().any(
      (declaration) => declaration.namePart.typeName.lexeme == name,
    );
  }
}

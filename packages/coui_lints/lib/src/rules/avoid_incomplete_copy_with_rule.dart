import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Flags a `copyWith` that does not list every field its class declares.
///
/// A field that is missing from `copyWith` is silently reset to whatever the
/// rebuilt constructor defaults it to — the caller asked to change one term
/// and lost another it never mentioned. The failure produces no error and no
/// visual difference until that term matters, which is why it is a rule
/// rather than a review item.
///
/// A field is accounted for when `copyWith` either accepts it as a named
/// parameter or reads it in its body — a copy may deliberately *preserve* a
/// term without letting callers change it (a directional inset stays
/// directional; a variant built through a named constructor stays that
/// variant). What the rule catches is the field nobody mentions, because
/// that is the one the rebuilt constructor fills with its default.
///
/// Only fields a constructor can set are required: static fields, private
/// fields (a named parameter cannot be private) and fields initialised at
/// their declaration are skipped. Inherited fields are the superclass's
/// `copyWith` to account for, and an abstract `copyWith` states a contract
/// its implementations fulfil, so it is skipped.
///
/// See `.claude/rules/core/style-contract.md` (`copyWith` 필드 완전성) and
/// `.claude/rules/code-style/lint-stack.md`.
class AvoidIncompleteCopyWithRule extends AnalysisRule {
  /// Creates the rule instance registered by the CoUI plugin.
  AvoidIncompleteCopyWithRule()
    : super(
        name: 'avoid_incomplete_copy_with',
        description:
            'copyWith should accept every field its class declares, so '
            'copying one term never resets another.',
      );

  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'avoid_incomplete_copy_with',
    'copyWith does not accept {0}; a copy silently resets '
        '{1} to its constructor default.',
    correctionMessage:
        'Add a named parameter for each missing field and pass it through '
        "as '<field>: <field> ?? this.<field>'.",
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

  final AvoidIncompleteCopyWithRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final copyWith = _copyWithOf(body);
    if (copyWith == null || copyWith.body is EmptyFunctionBody) return;

    final accepted = {
      for (final parameter
          in copyWith.parameters?.parameters ?? const <FormalParameter>[])
        if (parameter.isNamed) ?parameter.name?.lexeme,
    };
    final read = _FieldReadCollector();
    copyWith.body.accept(read);
    // A bare identifier that shares a field's name reads the parameter or
    // local that shadows it, not the field — only `this.<field>` sees
    // through the shadow.
    final shadowed = {
      for (final parameter
          in copyWith.parameters?.parameters ?? const <FormalParameter>[])
        ?parameter.name?.lexeme,
      ...read.locals,
    };

    final missing = [
      for (final field in _settableFields(body))
        if (!accepted.contains(field) &&
            !read.viaThis.contains(field) &&
            !(read.bare.contains(field) && !shadowed.contains(field)))
          field,
    ];
    if (missing.isEmpty) return;

    final listed = missing.map((name) => "'$name'").join(', ');
    final _ = rule.reportAtToken(
      copyWith.name,
      arguments: [listed, if (missing.length == 1) 'it' else 'them'],
    );
  }

  /// The instance `copyWith` method, or null when the class has none.
  MethodDeclaration? _copyWithOf(BlockClassBody body) {
    for (final member in body.members) {
      if (member is MethodDeclaration &&
          !member.isStatic &&
          !member.isGetter &&
          !member.isSetter &&
          member.name.lexeme == 'copyWith') {
        return member;
      }
    }
    return null;
  }

  /// Declared instance fields a constructor can set.
  Iterable<String> _settableFields(BlockClassBody body) sync* {
    for (final member in body.members) {
      if (member is! FieldDeclaration || member.isStatic) continue;
      for (final variable in member.fields.variables) {
        final name = variable.name.lexeme;
        if (name.startsWith('_')) continue;
        if (variable.initializer != null) continue;
        yield name;
      }
    }
  }
}

/// Collects what a `copyWith` body reads, split by how it reads it.
class _FieldReadCollector extends RecursiveAstVisitor<void> {
  /// Names read as `this.<name>` — always the field.
  final Set<String> viaThis = {};

  /// Names read bare — the field only when nothing shadows it.
  final Set<String> bare = {};

  /// Local variables declared in the body — they shadow a field of the same
  /// name.
  final Set<String> locals = {};

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target is ThisExpression) viaThis.add(node.propertyName.name);
    super.visitPropertyAccess(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    locals.add(node.name.lexeme);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    // `variant:` names the argument; `other.variant` / `a.b()` read
    // something else's member. None of them reads this class's field.
    final isOtherName =
        parent is Label ||
        (parent is PropertyAccess && parent.propertyName == node) ||
        (parent is PrefixedIdentifier && parent.identifier == node) ||
        (parent is MethodInvocation && parent.methodName == node);
    if (!isOtherName) bare.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

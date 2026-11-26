/// Shared AST helpers used by more than one CoUI lint rule.
library;

import 'package:analyzer/dart/ast/ast.dart';

/// Core token namespaces: `abstract final class` holders of `static const`
/// primitive values (e.g. `CoreSpace.space16`) — not domain types.
///
/// See `.claude/rules/core/design-tokens.md`, "원시토큰은 namespace 이지
/// enum/도메인 타입이 아니다".
const kCoreTokenNamespaces = {
  'CoreSpace',
  'CoreRadius',
  'CoreFontSize',
  'CoreDuration',
  'CoreSize',
  'CoreStrokeWidth',
};

final _kPrefixedConstantName = RegExp('^_k[A-Z]');

/// Whether [node] sits inside the initializer of a private, `_k`-prefixed
/// constant declaration (e.g. `_kDefaultDuration = Duration(...)`) — the
/// allow-listed local-constant escape hatch documented in
/// `.claude/rules/core/design-tokens.md`.
bool isWithinKPrefixedConstant(AstNode node) {
  final declaration = node.thisOrAncestorOfType<VariableDeclaration>();
  final name = declaration?.name.lexeme;
  return name != null && _kPrefixedConstantName.hasMatch(name);
}

/// Finds spacing that reaches the size factor (`* scaling`) without passing
/// through the theme density.
///
/// A density moves spacing one rung on the spacing scale, and on Flutter
/// the only place it can do that is where the resolver turns an authored
/// value into a paint-ready one. For insets that place is a conversion with
/// a `geometry` parameter, which the `pass_theme_geometry` lint holds every
/// call to. A spacing *double* has no conversion — it goes straight from
/// `merged.x ?? default` into `* scaling` — so nothing at compile time can
/// require it to pass through `theme.geometry.space(...)`. This reads the
/// resolvers instead.
///
/// What it flags: a `* scaling` product (either operand order, or `*=`)
/// whose other operand names a spacing value — any identifier matching
/// `spacing` or `gap`, case-insensitively — and is not itself a
/// `geometry.space(...)` call. The name is the only signal a raw double
/// carries; the rule that ties a spacing double's name to its role
/// (`resolver/scaling-and-gap.md`, `xxxSpacing` / `xxxGapStyle`) is what
/// makes it a reliable one.
///
/// What it does not flag: an operand that also names a dash (`dashGap`,
/// `dashSpacing`). The gap in a dash pattern belongs to the stroke it
/// draws, not to the layout around it, and a density that moved it would
/// re-draw a line rather than re-space a screen.
///
/// The source is parsed, not matched as text: a regular expression over
/// the same files once matched nothing — its pattern expected the operands
/// on one line, the code had them across two — and passed every file it
/// was meant to catch.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

final _kSpacingName = RegExp('spacing|gap', caseSensitive: false);
final _kDashName = RegExp('dash', caseSensitive: false);

/// One spacing value that reaches the size factor without the density.
class UnbentSpacing {
  /// Creates a finding.
  const UnbentSpacing({
    required this.path,
    required this.line,
    required this.source,
  });

  /// The file the product is in.
  final String path;

  /// The 1-based line the product starts on.
  final int line;

  /// The product, on one line.
  final String source;

  @override
  String toString() => '$path:$line  $source';
}

/// What a scan of one source found.
class SpacingScan {
  /// Creates a scan result.
  const SpacingScan({required this.products, required this.unbent});

  /// How many `* scaling` products the source holds — the population the
  /// check ran over. Zero across every file means the check read nothing.
  final int products;

  /// The products that carry spacing past the density.
  final List<UnbentSpacing> unbent;
}

/// Scans [source] (a Dart file at [path]) for spacing that reaches the size
/// factor without the density.
SpacingScan scanSource(String source, {required String path}) {
  final unit = parseString(
    content: source,
    path: path,
    throwIfDiagnostics: false,
  ).unit;
  final products = _ScalingProducts();
  unit.accept(products);

  return SpacingScan(
    products: products.operands.length,
    unbent: [
      for (final (:node, :operand) in products.operands)
        if (_carriesUnbentSpacing(operand))
          UnbentSpacing(
            path: path,
            line: unit.lineInfo.getLocation(node.offset).lineNumber,
            source: node.toSource().replaceAll(RegExp(r'\s+'), ' '),
          ),
    ],
  );
}

/// Whether [operand] names a spacing value that has not been through
/// `geometry.space(...)`.
bool _carriesUnbentSpacing(Expression operand) {
  if (_isDensityStep(operand)) return false;

  final names = _Names();
  operand.accept(names);
  if (names.found.any(_kDashName.hasMatch)) return false;
  return names.found.any(_kSpacingName.hasMatch);
}

/// `geometry.space(x)`, `theme.geometry.space(x)` or
/// `Theme.of(context).geometry.space(x)`.
bool _isDensityStep(Expression expression) {
  final call = expression.unParenthesized;
  if (call is! MethodInvocation || call.methodName.name != 'space') {
    return false;
  }
  return _namesGeometry(call.target);
}

bool _namesGeometry(Expression? target) => switch (target?.unParenthesized) {
  SimpleIdentifier(:final name) => name == 'geometry',
  PrefixedIdentifier(:final identifier) => identifier.name == 'geometry',
  PropertyAccess(:final propertyName) => propertyName.name == 'geometry',
  _ => false,
};

/// `scaling`, `theme.scaling` or `Theme.of(context).scaling`.
bool _isScaling(Expression expression) => switch (expression.unParenthesized) {
  SimpleIdentifier(:final name) => name == 'scaling',
  PrefixedIdentifier(:final identifier) => identifier.name == 'scaling',
  PropertyAccess(:final propertyName) => propertyName.name == 'scaling',
  _ => false,
};

/// Every `* scaling` product in a unit, paired with its other operand.
class _ScalingProducts extends RecursiveAstVisitor<void> {
  final operands = <({AstNode node, Expression operand})>[];

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.STAR) {
      if (_isScaling(node.rightOperand)) {
        operands.add((node: node, operand: node.leftOperand));
      } else if (_isScaling(node.leftOperand)) {
        operands.add((node: node, operand: node.rightOperand));
      }
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type == TokenType.STAR_EQ &&
        _isScaling(node.rightHandSide)) {
      operands.add((node: node, operand: node.leftHandSide));
    }
    super.visitAssignmentExpression(node);
  }
}

/// Every identifier an expression names.
class _Names extends RecursiveAstVisitor<void> {
  final found = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    found.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

/// Scans every `*_style.dart` under `--root` and compares the count of
/// unbent spacing with `--baseline`.
///
/// Exit codes: 0 at or under the baseline, 1 over it, 2 when the check
/// read nothing (no file, or no `* scaling` product) — a check whose target
/// moved is not evidence of compliance.
void main(List<String> args) {
  String? option(String name) {
    final index = args.indexOf(name);
    return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
  }

  final root = option('--root');
  final baseline = int.tryParse(option('--baseline') ?? '');
  if (root == null || baseline == null) {
    stderr.writeln(
      'usage: density_spacing_reach.dart --root <dir> --baseline <count>',
    );
    exit(2);
  }

  final directory = Directory(root);
  if (!directory.existsSync()) {
    stderr.writeln('❌ $root not found — nothing to check.');
    exit(2);
  }

  final files =
      directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_style.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var products = 0;
  final unbent = <UnbentSpacing>[];
  for (final file in files) {
    final relative = file.path.substring(directory.path.length + 1);
    final scan = scanSource(file.readAsStringSync(), path: relative);
    products += scan.products;
    unbent.addAll(scan.unbent);
  }

  if (files.isEmpty || products == 0) {
    stderr.writeln(
      '❌ Read ${files.length} resolver files and $products `* scaling` '
      'products under $root — a check that reads nothing cannot tell '
      '"compliant" from "pointed at the wrong place".',
    );
    exit(2);
  }

  stdout.writeln(
    'density spacing reach — ${files.length} resolvers, $products '
    '`* scaling` products, ${unbent.length} carry spacing past the density '
    '(baseline $baseline)',
  );
  for (final finding in unbent) {
    stdout.writeln('  $finding');
  }

  if (unbent.length > baseline) {
    stdout
      ..writeln()
      ..writeln(
        '❌ ${unbent.length - baseline} net-new: a spacing value reaches '
        '`* scaling` without the theme density.',
      )
      ..writeln(
        '   Wrap the authored value before the size factor: '
        '`theme.geometry.space(x) * scaling`.',
      )
      ..writeln(
        '   If the value is not spacing — a position, a size, a replica '
        "of a device's geometry — name it for what it is, or count it in "
        'the baseline file with the reason.',
      );
    exit(1);
  }

  if (unbent.length < baseline) {
    stdout.writeln(
      '✅ ${baseline - unbent.length} under the baseline — lower it to '
      '${unbent.length} so the gain cannot be spent.',
    );
  } else {
    stdout.writeln('✅ no net-new spacing past the density.');
  }
}

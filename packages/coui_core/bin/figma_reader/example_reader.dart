/// Per-component sugar-chain examples (schema v3 `examples` — FR-004).
///
/// What gets stored is deliberately narrow (S-001 / CH-008): only the two
/// snippets that cannot be derived from `axes` downstream —
///
///   `withStyle`   — the real chain *expression* from the component's docs
///                   preview (`{slug}_chain_example.dart`, flutter 우선 —
///                   Flutter-first tie-break), extracted with its original
///                   formatting; never the verbatim example class (a
///                   StatefulWidget wrapper is boilerplate on a Figma code
///                   block and ~24 lines of JSON bloat per component).
///                   Fallback: a canonical one-liner when the component has
///                   a `{Pascal}StyleChain` extension but no docs example;
///                   `null` (counted) when it has neither.
///   `tokenChain`  — a canonical one-liner using a real zero-arg getter on
///                   the StyleChain extension. The getter name is read from
///                   source so the snippet can never name an API that
///                   doesn't exist. When the docs chain ends on the same
///                   getter `defaultBorderRadius` names
///                   (`Carousel(…).radius16`), that getter is the stamp —
///                   the page otherwise prints `.radius16` beside
///                   `….radius0`, the extension's first getter. Every other
///                   component keeps that first getter (`Badge(…).radius0`).
///
/// The basic-constructor snippet is *not* stored — the plugin derives it
/// from `axes` (defaultVariant + required surface), so a rename in code
/// flows through without a re-export of prose.
///
/// Extension discovery is a line-shape scan, not AST: the T-1 AST mandate
/// exists because token *identity* dies in evaluated values, but here the
/// payload IS the literal source text (an extension header and a getter
/// name), which a line scan preserves exactly.
// ignore_for_file: depend_on_referenced_packages
// `analyzer` is a direct `dev_dependency` of this package — see
// `style_reader.dart`'s matching ignore.
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'parse_source.dart';

/// One component's example surface.
final class ComponentExamples {
  const ComponentExamples({required this.withStyle, required this.tokenChain});

  static const ComponentExamples none = ComponentExamples(
    withStyle: null,
    tokenChain: null,
  );

  final String? withStyle;
  final String? tokenChain;
}

/// JSON shape for one component's `examples` key — keys always present.
Map<String, dynamic> examplesJson(ComponentExamples examples) => {
  'withStyle': examples.withStyle,
  'tokenChain': examples.tokenChain,
};

/// Reads examples for every slug in [slugs].
///
/// [examplesRoot] — `docs_core/lib/previews/examples` (contains
/// `flutter/` and `web/` subtrees). [componentsRoot] —
/// `packages/coui_flutter/lib/src/components` (where the StyleChain
/// extensions live).
Map<String, ComponentExamples> readExamples({
  required String examplesRoot,
  required String componentsRoot,
  required Iterable<String> slugs,
  String? contractsRoot,
}) {
  final widgetFileBySlug = _indexWidgetFiles(componentsRoot);
  final result = <String, ComponentExamples>{};

  for (final slug in slugs) {
    final pascal = _pascalOf(slug);

    String? withStyle;
    // Flutter 우선 — 모호하면 Flutter 를 따른다.
    for (final platform in const ['flutter', 'web']) {
      final path = '$examplesRoot/$platform/$slug/${slug}_chain_example.dart';
      final file = File(path);
      if (!file.existsSync()) continue;
      withStyle = _chainExpression(file.readAsStringSync(), path);
      if (withStyle != null) break;
    }

    String? firstGetter;
    var hasExtension = false;
    var getters = const <String>[];
    final widgetPath = widgetFileBySlug[slug];
    if (widgetPath != null) {
      final scan = _scanStyleChainExtension(
        File(widgetPath).readAsStringSync(),
        pascal: pascal,
      );
      hasExtension = scan.hasExtension;
      firstGetter = scan.firstGetter;
      getters = scan.getters;
    }

    if (withStyle == null && hasExtension) {
      withStyle = '$pascal(…).withStyle(const Core${pascal}Style(…))';
    }
    final tokenGetter = _tokenGetter(
      firstGetter: firstGetter,
      getters: getters,
      withStyle: withStyle,
      defaultRadiusGetter: _defaultRadiusGetter(contractsRoot, slug),
    );
    final tokenChain = tokenGetter == null ? null : '$pascal(…).$tokenGetter';

    result[slug] = ComponentExamples(
      withStyle: withStyle,
      tokenChain: tokenChain,
    );
  }
  return result;
}

/// Maps slug → the widget file expected to carry the StyleChain extension
/// (`…/{category}/{slug}/{slug}.dart`, or file-shaped `…/{slug}.dart`).
Map<String, String> _indexWidgetFiles(String componentsRoot) {
  final root = Directory(componentsRoot);
  if (!root.existsSync()) {
    throw StateError('components root not found: $componentsRoot');
  }
  final byQuery = <String, String>{};
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.endsWith('.dart'))
          .toList()
        ..sort();
  for (final path in files) {
    final base = path.split(Platform.pathSeparator).last;
    final slug = base.substring(0, base.length - '.dart'.length);
    // First sorted match wins — deterministic, and the canonical widget
    // file `{slug}/{slug}.dart` sorts before deeper duplicates in practice.
    if (!byQuery.containsKey(slug)) byQuery[slug] = path;
  }
  return byQuery;
}

/// Extracts the outermost expression containing a `.withStyle(…)` call,
/// preserving the author's original formatting (source span, not
/// `toSource()`'s single-line flattening).
String? _chainExpression(String source, String path) {
  final result = parseSource(content: source, path: path);
  if (result.errors.isNotEmpty) return null;
  final visitor = _WithStyleVisitor();
  result.unit.accept(visitor);
  final node = visitor.first;
  if (node == null) return null;

  AstNode top = node;
  while (true) {
    final parent = top.parent;
    if (parent is MethodInvocation ||
        parent is PropertyAccess ||
        parent is CascadeExpression ||
        parent is ParenthesizedExpression) {
      top = parent!;
      continue;
    }
    break;
  }
  return _dedent(source.substring(top.offset, top.end));
}

final class _WithStyleVisitor extends RecursiveAstVisitor<void> {
  MethodInvocation? first;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (first == null && node.methodName.name == 'withStyle') {
      first = node;
    }
    super.visitMethodInvocation(node);
  }
}

/// Strips the common leading indentation the expression carried inside its
/// example class, so the snippet sits flush in a Figma code block.
String _dedent(String snippet) {
  final lines = snippet.split('\n');
  if (lines.length < 2) return snippet;
  int? common;
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final indent = line.length - line.trimLeft().length;
    common = common == null || indent < common ? indent : common;
  }
  final cut = common;
  if (cut == null || cut == 0) return snippet;
  return [
    lines.first,
    ...lines.skip(1).map((l) => l.length >= cut ? l.substring(cut) : l),
  ].join('\n');
}

/// Line-shape scan for `extension {Pascal}StyleChain` and its zero-arg
/// getters returning the component type. `firstGetter` is the source-order
/// first; `getters` is every name, so a later radius step can be chosen
/// when it is the one the docs chain and the style default both name.
({bool hasExtension, String? firstGetter, List<String> getters})
_scanStyleChainExtension(
  String source, {
  required String pascal,
}) {
  final extensionHeader = RegExp('extension ${pascal}StyleChain on $pascal');
  final headerMatch = extensionHeader.firstMatch(source);
  if (headerMatch == null) {
    return (hasExtension: false, firstGetter: null, getters: const []);
  }
  final body = source.substring(headerMatch.end);
  final getters = <String>[
    for (final match in RegExp(
      '$pascal get ([a-zA-Z][a-zA-Z0-9]*)',
    ).allMatches(body))
      ?match.group(1),
  ];
  return (
    hasExtension: true,
    firstGetter: getters.isEmpty ? null : getters.first,
    getters: getters,
  );
}

/// The `CoreRadius` step `defaultBorderRadius` is built from, when the
/// style file states `CoreBorderRadius.all(CoreRadius.radiusN)`.
String? _defaultRadiusGetter(String? contractsRoot, String slug) {
  if (contractsRoot == null) return null;
  final file = File('$contractsRoot/$slug/${slug}_style.dart');
  if (!file.existsSync()) return null;
  return RegExp(
    r'defaultBorderRadius\s*=\s*CoreBorderRadius\.all\(\s*'
    r'CoreRadius\.(radius[0-9]+)\s*,?\s*\)',
  ).firstMatch(file.readAsStringSync())?.group(1);
}

/// The getter `tokenChain` names.
///
/// The extension's first getter is the default stamp. When the authored
/// chain example ends on a getter that the extension declares AND that
/// getter is the style's `defaultBorderRadius` step, that getter wins:
/// it is the corner the page is teaching and the corner the canvas binds.
String? _tokenGetter({
  required String? firstGetter,
  required List<String> getters,
  required String? withStyle,
  required String? defaultRadiusGetter,
}) {
  if (withStyle != null && defaultRadiusGetter != null) {
    final terminal = RegExp(
      r'\.([A-Za-z][A-Za-z0-9]*)\s*$',
    ).firstMatch(withStyle.trim())?.group(1);
    if (terminal == defaultRadiusGetter && getters.contains(terminal)) {
      return terminal;
    }
  }
  return firstGetter;
}

String _pascalOf(String slug) => slug
    .split('_')
    .map((seg) => seg.isEmpty ? seg : seg[0].toUpperCase() + seg.substring(1))
    .join();

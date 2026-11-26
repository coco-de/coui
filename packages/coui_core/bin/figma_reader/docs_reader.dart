/// Per-component docs surface (schema v3 `docs` — FR-003).
///
/// Three structured sources, one priority order:
///
///   1. `docs_core/content/blocks/{kebab}.md` frontmatter `description:`
///      — Korean, for a Block page (`lang: "ko"`, url `/blocks/{kebab}`).
///      Wins over a component page of the same slug.
///   2. `docs_core/content/components/{kebab}.md` frontmatter `description:`
///      — Korean, the primary voice of docs_site (`lang: "ko"`).
///   3. `docs_core/lib/shared/component_catalog.dart`'s
///      `DocsComponentEntry(slug:, description:)` — English one-liners,
///      fallback only (`lang: "en"`).
///
/// Neither source having the component leaves `description: null` — counted
/// by the exporter so the gap list is a printed fact, not a silent shrug
/// (the standing R-2 concern: registry 101 ↔ content md 139 correspondence
/// must be observable).
///
/// `url` points at the docs_site page: `/blocks/{kebab}` when a block page
/// supplied the description, otherwise `/components/{kebab}`. `slugs`
/// records the three spellings that already coexist in this repo
/// (kebab for docs, snake for components.json, Pascal for the plugin
/// REGISTRY) so no consumer ever re-derives a fourth.
// ignore_for_file: depend_on_referenced_packages
// `analyzer` is a direct `dev_dependency` of this package — see
// `style_reader.dart`'s matching ignore.
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

import 'ast_value.dart' show namedArg;
import 'parse_source.dart';

/// The docs_site origin. Single home for the base URL on the exporter
/// side — the deployed docs origin is operational fact, not coui_core
/// state, so a constant here (next to the one consumer) beats threading it
/// through every call site.
const kDocsSiteBaseUrl = 'https://coui.cocode.im';

/// One component's docs surface.
final class ComponentDocs {
  const ComponentDocs({
    required this.description,
    required this.lang,
    this.order,
    this.section,
  });

  final String? description;

  /// `ko` (content md frontmatter) or `en` (catalog fallback); `null` when
  /// no source had the component.
  final String? lang;

  /// This component's position in `kDocsComponentEntries` — the flat,
  /// curated (not alphabetical) order the sidebar and overview grid render
  /// in. `null` for a component the catalog doesn't list at all (an
  /// undocumented/infra-internal one, including a Block) — the exporter
  /// counts that gap rather than fabricating a position.
  final int? order;

  /// docs_site section the page lives under. `blocks` when a block markdown
  /// page won the description; null means the component catalog path.
  final String? section;
}

/// JSON shape for one component's `docs` key — every key always present
/// (schema v2's "union 금지" rule).
Map<String, dynamic> docsJson(
  ComponentDocs? docs, {
  required String snakeSlug,
}) {
  final kebab = snakeSlug.replaceAll('_', '-');
  final section = docs?.section ?? 'components';
  return {
    'description': docs?.description,
    'lang': docs?.lang,
    'url': '$kDocsSiteBaseUrl/$section/$kebab',
    'order': docs?.order,
    'slugs': {
      'kebab': kebab,
      'snake': snakeSlug,
      'pascal': _pascalOf(snakeSlug),
    },
  };
}

/// Reads both description sources, keyed by *kebab* slug (both sources'
/// native spelling).
Map<String, ComponentDocs> readDocs({
  required String contentRoot,
  required String catalogPath,
  String? blocksRoot,
}) {
  final byKebab = <String, ComponentDocs>{};

  // Catalog first, md second — the md loop overwrites, which IS the
  // priority order (Korean md wins over English catalog).
  final catalog = File(catalogPath);
  if (!catalog.existsSync()) {
    throw StateError('component catalog not found: $catalogPath');
  }
  final catalogResult = parseSource(
    content: catalog.readAsStringSync(),
    path: catalogPath,
  );
  if (catalogResult.errors.isNotEmpty) {
    throw StateError('failed to parse $catalogPath');
  }
  // Read once, applied to every entry below regardless of which loop last
  // wrote it — `order` is a structural fact about the catalog, independent
  // of which source won the *description* priority race.
  final orderByKebab = _catalogOrder(catalogResult.unit);
  for (final entry in _catalogEntries(catalogResult.unit).entries) {
    byKebab[entry.key] = ComponentDocs(
      description: entry.value,
      lang: 'en',
      order: orderByKebab[entry.key],
    );
  }

  final contentDir = Directory(contentRoot);
  if (!contentDir.existsSync()) {
    throw StateError('docs content root not found: $contentRoot');
  }
  final mdFiles =
      contentDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .map((f) => f.path)
          .toList()
        ..sort();
  for (final path in mdFiles) {
    final kebab = path
        .split(Platform.pathSeparator)
        .last
        .replaceAll(RegExp(r'\.md$'), '');
    final description = _frontmatterDescription(File(path).readAsStringSync());
    if (description != null) {
      // A fresh `ComponentDocs` here overwrites the whole record, `order`
      // included — re-attached from the catalog map rather than carried
      // over, or a documented-but-catalog-absent component would silently
      // lose the position the earlier loop never had to give it.
      byKebab[kebab] = ComponentDocs(
        description: description,
        lang: 'ko',
        order: orderByKebab[kebab],
      );
    }
  }

  if (blocksRoot != null) {
    final blocksDir = Directory(blocksRoot);
    if (!blocksDir.existsSync()) {
      throw StateError('docs blocks root not found: $blocksRoot');
    }
    final blockFiles =
        blocksDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .map((f) => f.path)
            .toList()
          ..sort();
    for (final path in blockFiles) {
      final kebab = path
          .split(Platform.pathSeparator)
          .last
          .replaceAll(RegExp(r'\.md$'), '');
      // `index.md` is the section landing page, not a block entry.
      if (kebab == 'index') continue;
      final description = _frontmatterDescription(
        File(path).readAsStringSync(),
      );
      if (description != null) {
        byKebab[kebab] = ComponentDocs(
          description: description,
          lang: 'ko',
          order: orderByKebab[kebab],
          section: 'blocks',
        );
      }
    }
  }

  return byKebab;
}

/// Extracts `description:` from a leading `---` frontmatter block. Plain
/// line-scan, not a YAML parser — the frontmatter here is a flat key:value
/// block by construction (docs-site's own loader assumes the same), and a
/// YAML dependency would be this script's first.
String? _frontmatterDescription(String source) {
  final lines = source.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return null;
  for (final line in lines.skip(1)) {
    final trimmed = line.trim();
    if (trimmed == '---') return null; // block ended without a description
    if (trimmed.startsWith('description:')) {
      final value = trimmed.substring('description:'.length).trim();
      return value.isEmpty ? null : value;
    }
  }
  return null;
}

/// The argument list of a `TypeName(...)` call, whichever node shape the
/// unresolved parser gave it.
///
/// `component_catalog.dart` writes `DocsComponentGroup(...)` /
/// `DocsComponentEntry(...)` with no `const`/`new` keyword on the individual
/// call (only the outer `const List<...> kDocsComponentGroups = [...]`
/// carries `const`, which does not propagate into making each nested call an
/// `InstanceCreationExpression` — `ast_value.dart`'s `readValue` documents the
/// exact same ambiguity: without an explicit keyword at the call site, the
/// *unresolved* parser cannot tell a constructor call from a plain function
/// call and always emits `MethodInvocation`). A matcher that only checked
/// `InstanceCreationExpression` would silently match nothing here — which is
/// exactly what this reader did before this fix: `_catalogEntries` and the
/// order walk below both returned empty on this file, invisibly, because an
/// empty catalog fallback and a catalog with nothing left to fall back to
/// look identical from the outside.
ArgumentList? _constructorCall(AstNode node, String typeName) {
  if (node is InstanceCreationExpression &&
      node.constructorName.type.name.lexeme == typeName) {
    return node.argumentList;
  }
  if (node is MethodInvocation &&
      node.target == null &&
      node.methodName.name == typeName) {
    return node.argumentList;
  }
  return null;
}

/// Collects `DocsComponentEntry(slug: '…', description: '…')` pairs via an
/// explicit worklist walk — the same manual-traversal idiom as the other
/// figma_reader files (no `RecursiveAstVisitor` field-accumulation).
Map<String, String> _catalogEntries(CompilationUnit unit) {
  final entries = <String, String>{};
  final worklist = <AstNode>[unit];
  while (worklist.isNotEmpty) {
    final node = worklist.removeLast();
    worklist.addAll(node.childEntities.whereType());
    final args = _constructorCall(node, 'DocsComponentEntry');
    if (args == null) continue;
    String? slug;
    String? description;
    // `namedArg` — ast_value.dart's version-portability adapter for the
    // analyzer's named-argument wrapper churn point; never reference the
    // version-specific wrapper type names here (the churn guard scans this
    // directory for them, comments included).
    for (final Object arg in args.arguments) {
      final na = namedArg(arg);
      if (na == null) continue;
      final value = na.value;
      if (value is! SimpleStringLiteral) continue;
      if (na.name == 'slug') slug = value.value;
      if (na.name == 'description') description = value.value;
    }
    if (slug != null && description != null) {
      entries[slug] = description;
    }
  }
  return entries;
}

/// The curated position of every `DocsComponentEntry` in
/// `kDocsComponentGroups`, flattened to a single sequential index —
/// slug → the same index `kDocsComponentEntries` (the flat spread the
/// sidebar/grid/search actually iterate) assigns it.
///
/// A STRUCTURED walk, unlike `_catalogEntries`'s generic worklist: order is
/// exactly the thing a stack-based (LIFO) traversal cannot be trusted to
/// preserve, since popping "last pushed first" visits a list's later
/// elements before its earlier ones. Reading `kDocsComponentGroups`'
/// initializer as a `ListLiteral` and iterating `.elements` — and each
/// group's `items:` argument the same way — is a plain top-to-bottom
/// left-to-right read of the literal exactly as it appears in the source,
/// which a stack walk does not give for free.
Map<String, int> _catalogOrder(CompilationUnit unit) {
  ListLiteral? groups;
  for (final decl in unit.declarations) {
    if (decl is! TopLevelVariableDeclaration) continue;
    for (final variable in decl.variables.variables) {
      if (variable.name.lexeme != 'kDocsComponentGroups') continue;
      final initializer = variable.initializer;
      if (initializer is ListLiteral) groups = initializer;
    }
  }
  if (groups == null) return const {};

  final order = <String, int>{};
  for (final groupExpr in groups.elements) {
    final groupArgs = _constructorCall(groupExpr, 'DocsComponentGroup');
    if (groupArgs == null) continue;
    ListLiteral? items;
    for (final Object arg in groupArgs.arguments) {
      final na = namedArg(arg);
      if (na != null && na.name == 'items' && na.value is ListLiteral) {
        items = na.value as ListLiteral;
      }
    }
    if (items == null) continue;
    for (final itemExpr in items.elements) {
      final itemArgs = _constructorCall(itemExpr, 'DocsComponentEntry');
      if (itemArgs == null) continue;
      String? slug;
      for (final Object arg in itemArgs.arguments) {
        final na = namedArg(arg);
        final value = na?.value;
        if (na?.name == 'slug' && value is SimpleStringLiteral) {
          slug = value.value;
        }
      }
      if (slug != null) order[slug] = order.length;
    }
  }
  return order;
}

String _pascalOf(String slug) => slug
    .split('_')
    .map((seg) => seg.isEmpty ? seg : seg[0].toUpperCase() + seg.substring(1))
    .join();

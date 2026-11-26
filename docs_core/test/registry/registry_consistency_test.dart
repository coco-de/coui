import 'dart:io';

import 'package:test/test.dart';

import 'package:docs_core/previews/code_registry.dart';
import 'package:docs_core/shared/block_catalog.dart';
import 'package:docs_core/shared/component_catalog.dart';

/// Parses all `<LivePreview>` tags from component markdown files.
///
/// Returns a map of component name → list of variants.
/// If no variants attribute, the list contains a single `null`.
Map<String, List<String?>> parseMarkdownPreviews() {
  final dirs = [
    Directory('content/components'),
    Directory('content/blocks'),
  ];
  final result = <String, List<String?>>{};

  for (final dir in dirs) {
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.md')) continue;

      final content = file.readAsStringSync();
      final regex = RegExp(
        r'<LivePreview\s+component="([^"]+)"'
        r'(?:\s+variants?="([^"]+)")?',
      );

      for (final match in regex.allMatches(content)) {
        final component = match.group(1)!;
        final variantsAttr = match.group(2);

        if (variantsAttr != null) {
          result[component] = variantsAttr.split(',').map((v) => v.trim()).toList();
        } else {
          result.putIfAbsent(component, () => [null]);
        }
      }

      // v2 페이지(`docs_template.dart`)는 컴포넌트를 플레이그라운드로
      // 보여 준다 — 그 컴포넌트의 기본 미리보기가 페이지에 있는 것이다.
      for (final match in RegExp(r'<Playground\s+component="([^"]+)"').allMatches(content)) {
        result.putIfAbsent(match.group(1)!, () => [null]);
      }
    }
  }

  return result;
}

void main() {
  // Web and Flutter registries import platform-specific packages
  // (jaspr, flutter) so we cannot import them in a pure dart test.
  // Instead, we extract their keys via source parsing.

  late Set<String> webKeys;
  late Set<String> flutterKeys;
  late Set<String> codeKeys;
  late Map<String, List<String?>> markdownPreviews;

  // Deprecated whole-component slugs are exempt from the Web-side registries
  // (web/code): their Web implementation is fully deleted
  // (process/component-creation.md policy) while the Flutter demo and
  // markdown page survive for the deprecation window. Flutter-side coverage
  // is still required for every catalog slug, deprecated or not.
  final deprecatedSlugs = kDocsComponentEntries.where((e) => e.isDeprecated).map((e) => e.slug).toSet();

  // Block pages follow the block template (`docs_template.dart`): the layout
  // figure (`<BlockCatalogVisual>`) stands where a component page puts its
  // `<LivePreview>`, so a block's registry entry has no page that draws it.
  // The entries stay — the chain example generator still reads them.
  final blockSlugs = kDocsBlocks.map((e) => e.slug).toSet();

  /// Parses registry keys from the top-level Map literal in the source file.
  ///
  /// Matches `'key': builder,` patterns. The value is a function reference
  /// that may be public (`buttonCode`, in `code_registry.dart`) or private
  /// (`_buttonPreview`, in the platform registries) — accept either.
  Set<String> parseRegistryKeys(String path) {
    final content = File(path).readAsStringSync();
    // Match lines like:  'button': _buttonPreview,  or  'button': buttonCode,
    final regex = RegExp(
      r"^\s*'([a-z][a-z0-9-]*)'\s*:\s*[_a-zA-Z]",
      multiLine: true,
    );
    return regex.allMatches(content).map((m) => m.group(1)!).toSet();
  }

  setUpAll(() {
    webKeys = parseRegistryKeys('lib/previews/web_registry.dart');
    flutterKeys = parseRegistryKeys('lib/previews/flutter_registry.dart');
    codeKeys = parseRegistryKeys('lib/previews/code_registry.dart');
    markdownPreviews = parseMarkdownPreviews();
  });

  group('Registry key consistency', () {
    test('web and flutter registries have identical keys', () {
      final webOnly = webKeys.difference(flutterKeys);
      final flutterOnly = flutterKeys.difference(webKeys).difference(deprecatedSlugs);

      expect(
        webOnly,
        isEmpty,
        reason: 'Web-only keys (missing from flutter): $webOnly',
      );
      expect(
        flutterOnly,
        isEmpty,
        reason: 'Flutter-only keys (missing from web): $flutterOnly',
      );
    });

    test('web and code registries have identical keys', () {
      final webOnly = webKeys.difference(codeKeys);
      final codeOnly = codeKeys.difference(webKeys);

      expect(
        webOnly,
        isEmpty,
        reason: 'Web-only keys (missing from code): $webOnly',
      );
      expect(
        codeOnly,
        isEmpty,
        reason: 'Code-only keys (missing from web): $codeOnly',
      );
    });

    test('all three registries have the same count', () {
      final flutterActiveCount = flutterKeys.difference(deprecatedSlugs).length;
      expect(
        webKeys.length,
        equals(flutterActiveCount),
        reason: 'web=${webKeys.length}, flutter (active)=$flutterActiveCount',
      );
      expect(
        webKeys.length,
        equals(codeKeys.length),
        reason: 'web=${webKeys.length}, code=${codeKeys.length}',
      );
    });
  });

  group('Markdown LivePreview coverage', () {
    test('every markdown LivePreview component exists in all registries', () {
      for (final component in markdownPreviews.keys) {
        expect(
          flutterKeys,
          contains(component),
          reason: '"$component" in markdown but missing from flutter registry',
        );
        // Deprecated components keep their markdown page (deprecation
        // banner + Flutter-only demo) but their Web implementation is fully
        // deleted, so web/code registry coverage is not expected.
        if (deprecatedSlugs.contains(component)) continue;
        expect(
          webKeys,
          contains(component),
          reason: '"$component" in markdown but missing from web registry',
        );
        expect(
          codeKeys,
          contains(component),
          reason: '"$component" in markdown but missing from code registry',
        );
      }
    });

    test('every registry key has a corresponding markdown LivePreview', () {
      for (final key in webKeys.difference(blockSlugs)) {
        expect(
          markdownPreviews,
          contains(key),
          reason: '"$key" in registries but has no <LivePreview> in markdown',
        );
      }
    });

    test('at least one LivePreview exists', () {
      expect(markdownPreviews, isNotEmpty);
      expect(
        markdownPreviews.length,
        greaterThanOrEqualTo(80),
        reason: 'Expected 80+ components with LivePreview',
      );
    });
  });

  group('Code snippet registry', () {
    test('every builder returns non-empty string for null variant', () {
      for (final entry in kCodeSnippetRegistry.entries) {
        final result = entry.value(null);
        expect(
          result,
          isNotEmpty,
          reason: '${entry.key} default snippet is empty',
        );
      }
    });

    test('every documented variant returns non-empty snippet', () {
      for (final entry in markdownPreviews.entries) {
        final builder = kCodeSnippetRegistry[entry.key];
        if (builder == null) continue;

        for (final variant in entry.value) {
          final result = builder(variant);
          expect(
            result,
            isNotEmpty,
            reason: '${entry.key}/${variant ?? "default"} snippet is empty',
          );
        }
      }
    });
  });
}

import 'dart:io';

import 'package:test/test.dart';

import 'package:docs_core/previews/flutter_code_registry.dart';
import 'package:docs_core/shared/component_catalog.dart';

void main() {
  group('Flutter code snippet registry', () {
    test('every builder returns non-empty string for null variant', () {
      for (final entry in kFlutterCodeSnippetRegistry.entries) {
        final result = entry.value(null);
        expect(
          result,
          isNotEmpty,
          reason: '${entry.key} default Flutter snippet is empty',
        );
      }
    });

    test('has same keys as web code registry (parsed from source)', () {
      final webCodeKeys = _parseRegistryKeys('lib/previews/code_registry.dart');
      final flutterCodeKeys = kFlutterCodeSnippetRegistry.keys.toSet();

      final webOnly = webCodeKeys.difference(flutterCodeKeys);
      // Deprecated whole-component slugs are exempt: their Web implementation
      // is fully deleted (process/component-creation.md policy), so a
      // Flutter-only demo surviving alone is expected, not drift.
      final deprecatedSlugs = kDocsComponentEntries.where((e) => e.isDeprecated).map((e) => e.slug).toSet();
      final flutterOnly = flutterCodeKeys.difference(webCodeKeys).difference(deprecatedSlugs);

      expect(
        webOnly,
        isEmpty,
        reason: 'Web code-only keys (missing from Flutter code): $webOnly',
      );
      expect(
        flutterOnly,
        isEmpty,
        reason: 'Flutter code-only keys (missing from Web code): $flutterOnly',
      );
    });

    test('snippets contain valid Dart syntax markers', () {
      for (final entry in kFlutterCodeSnippetRegistry.entries) {
        final snippet = entry.value(null);
        // Every snippet should have at least one of: (, ), ., or keyword.
        expect(
          snippet.contains('(') || snippet.contains('.'),
          isTrue,
          reason: '${entry.key} Flutter snippet lacks Dart syntax: "$snippet"',
        );
      }
    });
  });
}

Set<String> _parseRegistryKeys(String path) {
  final content = File(path).readAsStringSync();
  // Match `'key': builder,` map entries. The value is a function reference
  // that may be public (`buttonCode`, in `code_registry.dart`) or private
  // (`_buttonPreview`, in the platform registries) — accept either.
  final regex = RegExp(
    r"^\s*'([a-z][a-z0-9-]*)'\s*:\s*[_a-zA-Z]",
    multiLine: true,
  );
  return regex.allMatches(content).map((m) => m.group(1)!).toSet();
}

@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/shared/preview_layout.dart';
import 'package:test/test.dart';

/// The Web preview stage states the width its Flutter twin fills.
///
/// A Flutter preview is a loose-constrained centre: a widget fills only when it
/// asks to. The Web stage centres its example in a flex column, which
/// content-sizes every root, so a root the Flutter side fills has to be stated
/// by the stage — [kDocsFillWidthPreviews], applied once in
/// [kWebPreviewRegistry] and read by both the docs site and the parity harness.
///
/// What these tests lock is the *list*: it names real components and real
/// variants, so a rename or a removed example cannot leave a key that silently
/// matches nothing. The rendered width is the parity capture's to prove.
void main() {
  List<String> declaredVariants(String component) {
    final md = File('content/components/$component.md').readAsStringSync();
    final tag = RegExp(
      '<LivePreview[^>]*component="$component"[^>]*>',
    ).firstMatch(md);
    final variants = tag == null ? null : RegExp('variants="([^"]*)"').firstMatch(tag.group(0)!)?.group(1);
    // A `<LivePreview>` with no `variants` shows the default example only.
    final live = variants == null ? const ['default'] : variants.split(',');
    // A v2 page (`docs_template.dart`) has no `<LivePreview>`: it shows a
    // registry example through `<Preview example>` / `<Card example>`, which
    // draws through the same [kWebPreviewRegistry] stage — so that is a
    // declaration too.
    final examples = [
      for (final block in RegExp('<(?:Preview|Card)\\b[^>]*component="$component"[^>]*>').allMatches(md))
        if (RegExp('example="([^"]*)"').firstMatch(block.group(0)!)?.group(1) case final example?) example,
    ];
    return [...live, ...examples];
  }

  group('every key names a component and a variant that exist', () {
    for (final key in kDocsFillWidthPreviews) {
      final parts = key.split('/');

      test(key, () {
        expect(parts, hasLength(2), reason: "keys are '<component>/<variant>'");
        final [component, variant] = parts;

        expect(
          kWebPreviewRegistry.containsKey(component),
          isTrue,
          reason: "'$component' is not in kWebPreviewRegistry",
        );
        expect(
          declaredVariants(component),
          contains(variant),
          reason: "content/components/$component.md declares no '$variant' variant",
        );
      });
    }
  });

  group('docsPreviewFillsWidth', () {
    test('an unnamed variant is the default one', () {
      expect(docsPreviewFillsWidth('disclosure', null), isTrue);
      expect(docsPreviewFillsWidth('disclosure', 'default'), isTrue);
    });

    test('a variant not listed stays content-sized', () {
      // The Flutter side of these is content-sized: a stacked list, a group.
      expect(docsPreviewFillsWidth('definition-list', null), isFalse);
      expect(docsPreviewFillsWidth('definition-list', 'inline'), isFalse);
      expect(docsPreviewFillsWidth('disclosure', 'group'), isFalse);
    });

    test('a component with no listed variant is untouched', () {
      expect(docsPreviewFillsWidth('button', null), isFalse);
      expect(docsPreviewFillsWidth('dot-indicator', null), isFalse);
    });
  });
}

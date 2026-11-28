import 'dart:io';

import 'package:docs_core/internal/preview/scenes.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/manifest/variant_registry.dart';

void main() {
  group('variantsForSlug', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('parity-variant-registry-');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('defaults to [default] when there is no content file', () {
      expect(
        variantsForSlug('nonexistent', contentDir: tempDir.path),
        ['default'],
      );
    });

    test('defaults to [default] when the file has no variants= attribute', () {
      File(p.join(tempDir.path, 'plain.md')).writeAsStringSync(
        '<LivePreview component="plain" />',
      );
      expect(variantsForSlug('plain', contentDir: tempDir.path), ['default']);
    });

    test('parses a comma-separated variants= attribute, order preserved', () {
      File(p.join(tempDir.path, 'card.md')).writeAsStringSync(
        '<LivePreview component="card" variants="default,filled,elevated" />',
      );
      expect(
        variantsForSlug('card', contentDir: tempDir.path),
        ['default', 'filled', 'elevated'],
      );
    });

    test('unions variants= across multiple LivePreview tags in one file', () {
      File(p.join(tempDir.path, 'date-picker.md')).writeAsStringSync('''
<LivePreview component="date-picker" variants="single,range" />
Some prose.
<LivePreview component="date-picker" variants="range,multi" />
''');
      expect(
        variantsForSlug('date-picker', contentDir: tempDir.path),
        ['single', 'range', 'multi'],
      );
    });

    test(
      'throws on a declared-but-empty variants attribute (no silent skip)',
      () {
        File(p.join(tempDir.path, 'broken.md')).writeAsStringSync(
          '<LivePreview component="broken" variants="" />',
        );
        expect(
          () => variantsForSlug('broken', contentDir: tempDir.path),
          throwsStateError,
        );
      },
    );

    test('throws when a comma-separated list has an empty segment', () {
      File(p.join(tempDir.path, 'trailing-comma.md')).writeAsStringSync(
        '<LivePreview component="x" variants="default," />',
      );
      expect(
        () => variantsForSlug('trailing-comma', contentDir: tempDir.path),
        throwsStateError,
      );
    });
  });

  group('variantsForSlug against real content', () {
    test(
      'a v2 page yields exactly the preview scenes its content declares',
      () {
        // Proves the wiring is data-driven, not a manifest-side per-component
        // table: a preview added to the docs page is part of the next run
        // without editing the matrix.
        const contentDir = 'docs_core/content/components';
        final path = p.join(contentDir, 'card.md');
        final source = File(path).readAsStringSync();
        final scenes = visibleDocsScenes(source, sourcePath: path);

        final variants = variantsForSlug('card', contentDir: contentDir);
        expect(
          variants,
          orderedEquals(scenes.map((scene) => scene.reference)),
        );
        expect(variants.length, greaterThan(1));

        // Read from the raw markdown, apart from the parser: no scene the page
        // names is left out.
        final named = RegExp(
          'demo="(card/[^"]+)"',
        ).allMatches(source).map((match) => match.group(1)!).toSet();
        expect(named, isNotEmpty);
        expect(
          scenes.map((scene) => scene.attributes['demo']).toSet(),
          containsAll(named),
        );

        // One more preview in a copy of the page is one more variant.
        final copy = Directory.systemTemp.createTempSync(
          'parity-variant-registry-',
        );
        addTearDown(() => copy.deleteSync(recursive: true));
        File(p.join(copy.path, 'card.md')).writeAsStringSync(
          '$source\n<Preview component="card" props="variant=outlined" '
          'label="added by the test" />\n',
        );
        final grown = variantsForSlug('card', contentDir: copy.path);
        expect(grown, hasLength(variants.length + 1));
        expect(grown, containsAll(variants));
      },
    );
  });
}

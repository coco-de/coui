import 'dart:io';

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
    test('a known multi-variant component picks up every declared variant', () {
      // Proves the wiring is data-driven, not a manifest-side per-component
      // table — #3604's completion definition: "새 variant 가 docs 예제에
      // 등록되면 매트릭스 편집 없이 다음 실행에 포함됨".
      final variants = variantsForSlug(
        'card',
        contentDir: 'docs_core/content/components',
      );
      expect(variants, containsAll(['default', 'filled', 'elevated']));
    });
  });
}

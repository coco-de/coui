import 'dart:io';

import 'package:coui_core/coui_core.dart' show CoreFontFamily;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/web/local_fonts.dart';

void main() {
  group('buildLocalFontFaceCss against the real vendored fonts', () {
    test('embeds both families with base64 data URIs, no file:// refs', () {
      final css = buildLocalFontFaceCss();
      expect(css, contains("font-family:'${CoreFontFamily.sans}'"));
      expect(css, contains("font-family:'${CoreFontFamily.mono}'"));
      expect(css, contains('data:font/otf;base64,'));
      expect(css, isNot(contains('file://')));
      expect(css, isNot(contains('http://')));
      expect(css, isNot(contains('https://')));
    });

    test('every standard weight name present as a file is emitted', () {
      final css = buildLocalFontFaceCss();
      for (final weight in kFontWeightNames.values) {
        expect(css, contains('font-weight:$weight;'), reason: 'weight $weight');
      }
    });

    test('the mono face covers the weights a code role can be drawn at', () {
      // Code roles are 400, and a surface style's weight floor can raise
      // them to 600 — each weight the stack can ask for needs its own
      // master, or the browser synthesizes a fake bold.
      final css = buildLocalFontFaceCss();
      for (final weight in [400, 500, 600, 700]) {
        expect(
          css,
          contains("font-family:'${CoreFontFamily.mono}';font-weight:$weight;"),
          reason: 'mono weight $weight',
        );
      }
    });

    test(
      'is memoized — a second call returns the identical string instance-equal content',
      () {
        final first = buildLocalFontFaceCss();
        final second = buildLocalFontFaceCss();
        expect(identical(first, second), isTrue);
      },
    );
  });

  group('buildLocalFontFaceCss against a fixture directory', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('parity-local-fonts-');
      Directory(
        p.join(tempRoot.path, kLocalFontsRelativeDir),
      ).createSync(recursive: true);
    });

    tearDown(() {
      tempRoot.deleteSync(recursive: true);
    });

    test('throws when the fonts directory does not exist', () {
      final emptyRoot = Directory.systemTemp.createTempSync('parity-no-fonts-');
      addTearDown(() => emptyRoot.deleteSync(recursive: true));
      expect(
        () => buildLocalFontFaceCss(repoRoot: emptyRoot.path),
        throwsStateError,
      );
    });

    test('throws when the fonts directory has nothing recognizable', () {
      File(
        p.join(tempRoot.path, kLocalFontsRelativeDir, 'readme.txt'),
      ).writeAsStringSync('not a font');
      expect(
        () => buildLocalFontFaceCss(repoRoot: tempRoot.path),
        throwsStateError,
      );
    });

    test('skips Variable files (no static font-weight range support here)', () {
      File(
        p.join(tempRoot.path, kLocalFontsRelativeDir, 'GeistMono-Variable.otf'),
      ).writeAsBytesSync([0, 1, 2, 3]);
      File(
        p.join(tempRoot.path, kLocalFontsRelativeDir, 'GeistMono-Regular.otf'),
      ).writeAsBytesSync([4, 5, 6, 7]);
      final css = buildLocalFontFaceCss(repoRoot: tempRoot.path);
      expect(css, contains('font-weight:400;'));
      // The Variable file's bytes ([0,1,2,3] -> base64 "AAECAw==") must not
      // appear — it was skipped, not silently mis-mapped to some weight.
      expect(css, isNot(contains('AAECAw==')));
    });

    test('reads a Geist file by Geist weight names, not the standard ones', () {
      // Geist `Black` is 800 and `UltraBlack` 900; the standard table would
      // declare `Black` as 900. `ExtraBold` is not a Geist name at all.
      File(
        p.join(tempRoot.path, kLocalFontsRelativeDir, 'GeistMono-Black.otf'),
      ).writeAsBytesSync([1, 1, 1]);
      File(
        p.join(
          tempRoot.path,
          kLocalFontsRelativeDir,
          'GeistMono-ExtraBold.otf',
        ),
      ).writeAsBytesSync([2, 2, 2]);
      final css = buildLocalFontFaceCss(repoRoot: tempRoot.path);
      expect(
        css,
        contains("font-family:'${CoreFontFamily.mono}';font-weight:800;"),
      );
      expect(css, isNot(contains('font-weight:900;')));
      // [2,2,2] -> base64 "AgIC" — skipped, not guessed at.
      expect(css, isNot(contains('AgIC')));
    });

    test('skips files that match neither vendored family prefix', () {
      File(
        p.join(
          tempRoot.path,
          kLocalFontsRelativeDir,
          'SomeOtherFont-Regular.ttf',
        ),
      ).writeAsBytesSync([9, 9, 9]);
      File(
        p.join(tempRoot.path, kLocalFontsRelativeDir, 'Pretendard-Regular.otf'),
      ).writeAsBytesSync([1, 2, 3]);
      final css = buildLocalFontFaceCss(repoRoot: tempRoot.path);
      expect(css, contains("font-family:'Pretendard'"));
      expect(css, isNot(contains('SomeOtherFont')));
    });
  });
}

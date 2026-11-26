import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_icons.dart';

/// A single icon needs no real layout space — small enough to keep the
/// headless window cheap, large enough that Chrome doesn't refuse to open
/// it.
const int _kViewportSize = 200;

/// Mirrors `offline_tailwind_harness_test.dart`'s system-Chrome lookup.
String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

void main() {
  group('loadVendoredIconifyScript / loadVendoredLucideCollectionJson', () {
    test('both vendored files are non-empty', () {
      expect(loadVendoredIconifyScript(), isNotEmpty);
      expect(loadVendoredLucideCollectionJson(), isNotEmpty);
    });

    test('the vendored collection covers a real icon name (home)', () {
      // Loose substring check on purpose — this file has no JSON decode
      // dependency, and the exact shape of one icon's entry isn't this
      // test's concern (that's an Iconify-format concern, not this repo's).
      // What matters here is that "home" is actually one of the 1817
      // vendored icons, not a typo'd example.
      expect(loadVendoredLucideCollectionJson(), contains('"home"'));
    });
  });

  group('buildLocalIconifyHeadHtml — script-close-tag neutralizing', () {
    late Directory fakeRepoRoot;

    setUp(() {
      fakeRepoRoot = Directory.systemTemp.createTempSync('local-icons-fake-');
      final vendorDir = Directory(
        p.join(fakeRepoRoot.path, 'tool/parity/vendor/iconify'),
      )..createSync(recursive: true);
      File(
        p.join(vendorDir.path, 'iconify-icon-2.1.0.js'),
      ).writeAsStringSync('/* fake custom element script */');
      final normalizer = File(
        p.join(fakeRepoRoot.path, 'packages/coui_web/lib/iconify_stroke.js'),
      );
      normalizer.parent.createSync(recursive: true);
      normalizer.writeAsStringSync('/* fake per-icon normalizer */');
    });

    tearDown(() {
      fakeRepoRoot.deleteSync(recursive: true);
    });

    /// A future vendor update legitimately mentioning `</script` inside a
    /// JSON string value (e.g. a `"description"` field) must not truncate
    /// the emitted HTML — this is the case [_neutralizeScriptCloseTag]
    /// exists for. Real collection data has never contained this today,
    /// so this exercises the defense with a fabricated payload rather than
    /// waiting for it to happen for real.
    test(
      'a literal </script inside the collection JSON does not survive '
      'into the emitted head fragment',
      () {
        File(
          p.join(
            fakeRepoRoot.path,
            'tool/parity/vendor/iconify/lucide-1.2.121.json',
          ),
        ).writeAsStringSync(
          '{"prefix":"lucide","icons":{"x":{"body":"<svg></svg>"}},'
          '"info":{"name":"a </script><script>alert(1)</script> tag"}}',
        );

        final headHtml = buildLocalIconifyHeadHtml(repoRoot: fakeRepoRoot.path);

        // Exactly the three legitimate closing tags this function itself
        // emits — none contributed by the embedded JSON payload.
        final closingTagCount = RegExp(
          '</script',
          caseSensitive: false,
        ).allMatches(headHtml).length;
        expect(closingTagCount, 3);
        // The payload's actual text survives, just de-fanged.
        expect(
          headHtml,
          contains(r'a <\/script><script>alert(1)<\/script> tag'),
        );
      },
    );

    test(
      'case is preserved when neutralizing (</SCRIPT stays </SCRIPT, '
      'only de-fanged)',
      () {
        File(
          p.join(
            fakeRepoRoot.path,
            'tool/parity/vendor/iconify/lucide-1.2.121.json',
          ),
        ).writeAsStringSync('{"info":{"name":"</SCRIPT>"}}');

        final headHtml = buildLocalIconifyHeadHtml(repoRoot: fakeRepoRoot.path);
        expect(headHtml, contains(r'<\/SCRIPT>'));
      },
    );
  });

  group('buildLocalIconifyHeadHtml (Chrome required)', () {
    final chromePath = _systemChromePath();
    late Browser browser;
    late Page page;
    late Directory tempDir;

    setUpAll(() async {
      browser = await launchCaptureBrowser(
        width: _kViewportSize,
        height: _kViewportSize,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      await browser.close();
    });

    setUp(() async {
      page = await browser.newPage();
      tempDir = Directory.systemTemp.createTempSync('local-icons-');
      // Confirms the fix actually removes the network dependency, not just
      // that a real Chrome happens to have connectivity right now — the
      // whole point of vendoring is that `api.iconify.design` is
      // unreachable and the icon still renders.
      await page.setOfflineMode(true);
    });

    tearDown(() async {
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    test(
      'a vendored lucide icon renders real SVG content in its shadow root',
      () async {
        final html =
            '''
<!doctype html>
<html><head>${buildLocalIconifyHeadHtml()}</head>
<body><iconify-icon icon="lucide:home"></iconify-icon></body></html>
''';
        final file = File(p.join(tempDir.path, 'icon.html'))
          ..writeAsStringSync(html);
        final _ = await page.goto(Uri.file(file.path).toString(), wait: .load);

        final svgOuterHtml = await page.evaluate<String?>(
          '''
() => {
            const el = document.querySelector('iconify-icon');
            const root = el && el.shadowRoot;
            const svg = root && root.querySelector('svg');
            return svg ? svg.outerHTML : null;
          }''',
        );

        expect(
          svgOuterHtml,
          isNotNull,
          reason:
              'shadow root had no <svg> — offline icon registration '
              'regressed (see local_icons.dart doc comment).',
        );
        expect(svgOuterHtml, contains('<path'));
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'an unvendored icon prefix renders an empty shadow root '
      '(documented gap, not a silent crash)',
      () async {
        final html =
            '''
<!doctype html>
<html><head>${buildLocalIconifyHeadHtml()}</head>
<body><iconify-icon icon="radix-icons:home"></iconify-icon></body></html>
''';
        final file = File(p.join(tempDir.path, 'icon.html'))
          ..writeAsStringSync(html);
        final _ = await page.goto(Uri.file(file.path).toString(), wait: .load);

        final hasSvg = await page.evaluate<bool>(
          '''
() => {
            const el = document.querySelector('iconify-icon');
            const root = el && el.shadowRoot;
            return !!(root && root.querySelector('svg'));
          }''',
        );
        expect(hasSvg, isFalse);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );
  });
}

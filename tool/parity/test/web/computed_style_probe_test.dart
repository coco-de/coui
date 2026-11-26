import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/computed_style_probe.dart';

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
  final chromePath = _systemChromePath();

  group('captureComputedStyle', () {
    late Browser browser;
    late Page page;
    late Directory tempDir;

    setUpAll(() async {
      browser = await launchCaptureBrowser(
        width: 400,
        height: 300,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      await browser.close();
    });

    setUp(() async {
      page = await browser.newPage();
      tempDir = Directory.systemTemp.createTempSync('computed-style-probe-');
    });

    tearDown(() async {
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    Future<void> loadHtml(String html) async {
      final file = File(p.join(tempDir.path, 'probe.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: Until.load);
    }

    test(
      'a box-less wrapper root is measured through to the box it holds',
      () async {
        // `display: contents` (a `BrightnessScope`) generates no box: its
        // rect is 0x0. The root is the box inside — what Flutter measures.
        await loadHtml('''
<html><body>
<div id="scope" style="display: contents">
  <div style="width: 30px; height: 20px; background-color: rgb(4,5,6);"></div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#scope');
        expect(result!['widthPx'], 30);
        expect(result['heightPx'], 20);
        expect(result['backgroundColor'], 'rgb(4, 5, 6)');

        final root = await findBoxRoot(page, '#scope');
        final box = await root!.boundingBox;
        expect(box!.width, 30);
        expect(box.height, 20);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a wrapper holding several boxes is not stepped through',
      () async {
        // No single box stands for it — the capture keeps the wrapper and
        // its 0x0 rect reports the degenerate root it is.
        await loadHtml('''
<html><body>
<div id="scope" style="display: contents">
  <div style="width: 30px; height: 20px;"></div>
  <div style="width: 30px; height: 20px;"></div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#scope');
        expect(result!['widthPx'], 0);
        expect(await findBoxRoot(page, '#missing'), isNull);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a visually hidden live region beside the content is not a second box',
      () async {
        // A `LoadingRegion` keeps a 1×1 out-of-flow status node next to its
        // content (inside a `display: contents` content wrapper of its own).
        // It is not drawn, so the wrapper still holds exactly one box — the
        // capture used to measure the 1×1 node instead of the content.
        await loadHtml('''
<html><body>
<div id="scope" style="display: contents">
  <div role="status" style="position: absolute; width: 1px; height: 1px;
    overflow: hidden; clip: rect(0,0,0,0);"></div>
  <div style="display: contents">
    <div style="width: 30px; height: 20px; background-color: rgb(4,5,6);"></div>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#scope');
        expect(result!['widthPx'], 30);
        expect(result['heightPx'], 20);

        final root = await findBoxRoot(page, '#scope');
        final box = await root!.boundingBox;
        expect(box!.width, 30);
        expect(box.height, 20);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a hidden live region before the box is skipped when it is the match',
      () async {
        // The `LoadingRegion` shape under the capture wrapper: the status
        // node is a *sibling* of the content, first in the DOM, so the root
        // selector (`[data-parity-key] > *`) lands on it. It is not drawn;
        // the root is the content next to it.
        await loadHtml('''
<html><body>
<div data-parity-key="k">
  <div id="hidden" role="status" style="position: fixed; width: 1px;
    height: 1px; overflow: hidden; clip: rect(0,0,0,0);"></div>
  <div style="display: contents">
    <div style="width: 30px; height: 20px; background-color: rgb(4,5,6);"></div>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key] > *',
        );
        expect(result!['widthPx'], 30);
        expect(result['heightPx'], 20);

        final root = await findBoxRoot(page, '[data-parity-key] > *');
        final box = await root!.boundingBox;
        expect(box!.width, 30);
        expect(box.height, 20);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a display: none sibling does not count as a second box',
      () async {
        await loadHtml('''
<html><body>
<div id="scope" style="display: contents">
  <style>.x { color: red; }</style>
  <div style="width: 30px; height: 20px;"></div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#scope');
        expect(result!['widthPx'], 30);
        expect(result['heightPx'], 20);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'an in-flow 1×1 element is a real box and still blocks stepping through',
      () async {
        // Only an *out-of-flow* 1×1 is treated as hidden. A box that takes
        // part in layout is a box, however small.
        await loadHtml('''
<html><body>
<div id="scope" style="display: contents">
  <div style="width: 1px; height: 1px;"></div>
  <div style="width: 30px; height: 20px;"></div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#scope');
        expect(result!['widthPx'], 0);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'reads every declared field as a raw browser string',
      () async {
        await loadHtml('''
<html><body>
<div id="x" style="font-family: monospace; font-weight: 700; font-size: 20px;
  color: rgb(1,2,3); background-color: rgb(4,5,6); padding: 1px 2px 3px 4px;
  border: 5px solid rgb(7,8,9); border-radius: 6px; opacity: 0.5;
  width: 20px;">hi</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#x');
        expect(result, isNotNull);
        expect(result!['fontFamily'], 'monospace');
        expect(result['fontWeight'], '700');
        expect(result['fontSize'], '20px');
        expect(result['color'], 'rgb(1, 2, 3)');
        expect(result['backgroundColor'], 'rgb(4, 5, 6)');
        expect(result['paddingTop'], '1px');
        expect(result['paddingRight'], '2px');
        expect(result['paddingBottom'], '3px');
        expect(result['paddingLeft'], '4px');
        expect(result['borderTopWidth'], '5px');
        expect(result['borderTopLeftRadius'], '6px');
        expect(result['opacity'], '0.5');
        // Geometry is a number, not a CSS string — it comes from
        // `getBoundingClientRect()`, and it is the BORDER box: 20px of
        // content + 2+4 padding + 5+5 border = 36 wide. `box.width`
        // would have said `20px` here (Chrome reports the content box
        // whatever `box-sizing` is), which is the wrong edge to compare
        // against Flutter's `RenderBox.size` and would have made every
        // padded component look divergent.
        expect(result['widthPx'], isA<num>());
        expect(result['heightPx'], isA<num>());
        // 20 content + (4+2) padding + (5+5) border. `box.width` says
        // `20px` for this same element — the content box — which is the
        // wrong edge to hold against Flutter's `RenderBox.size`.
        expect((result['widthPx']! as num).round(), 36);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'returns null when the selector matches nothing',
      () async {
        await loadHtml('<html><body><div id="x"></div></body></html>');
        final result = await captureComputedStyle(page, '#does-not-exist');
        expect(result, isNull);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a root under which nothing paints text reports the six text fields '
      'as null, not as its own inherited style',
      () async {
        // A `Divider`- or `Range`-shaped root: boxes only. Every element
        // has an inherited `color`, but there are no glyphs it applies to,
        // and the Flutter twin says `null` for the same shape.
        await loadHtml('''
<html><body style="color: rgb(1, 2, 3); font-size: 16px;">
<div id="x" style="background-color: rgb(4, 5, 6); height: 4px;">
  <div style="height: 2px;"></div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#x');
        expect(result, isNotNull);
        for (final field in const [
          'fontFamily',
          'fontWeight',
          'fontSize',
          'lineHeight',
          'letterSpacing',
          'color',
        ]) {
          expect(result![field], isNull, reason: field);
        }
        // The box half is still measured — only the text half is absent.
        expect(result!['backgroundColor'], 'rgb(4, 5, 6)');
        expect(result['widthPx'], isA<num>());
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'raw text that merely inherits still counts as text — the root '
      'fallback is kept',
      () async {
        // No colour class, no `text-inherit` span: nothing is a candidate,
        // but glyphs are on screen and inherit the root's style. That style
        // is what they paint with, so it is what gets reported.
        await loadHtml('''
<html><body style="color: rgb(1, 2, 3); font-size: 16px;">
<div id="x"><b>raw</b></div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#x');
        expect(result!['color'], 'rgb(1, 2, 3)');
        expect(result['fontSize'], '16px');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'text inside <style>, a hidden subtree, or whitespace is not text',
      () async {
        // A component's scoped <style> block is a text node too, and so is
        // the indentation between tags. Neither paints.
        await loadHtml('''
<html><body style="color: rgb(1, 2, 3);">
<div id="x">
  <style>.a { color: red; }</style>
  <div style="display: none;">hidden label</div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#x');
        expect(result!['color'], isNull);
        expect(result['fontFamily'], isNull);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a field holding a value is text even without a text node',
      () async {
        await loadHtml('''
<html><body style="color: rgb(1, 2, 3);">
<div id="x"><input value="typed"></div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#x');
        expect(result!['color'], isNotNull);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      "a > * selector reaches the wrapper's single child, not the wrapper",
      () async {
        await loadHtml('''
<html><body>
<div data-parity-key="k" style="font-size: 99px;">
  <span style="font-size: 12px;">child</span>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['fontSize'], '12px');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    // #3852 (Web half) — root-attribution: the matched (root) element does
    // NOT always own the text color/typography it reports. The three tests
    // below mirror `root_text_probe.dart`'s own three shapes (Flutter side)
    // in DOM/CSS terms. All three load a fake `window.tailwind.config` (the
    // Tailwind Play CDN global `declaresOwnColor` reads at capture time,
    // `computed_style_probe.dart`'s own doc comment) plus a `<style>` block
    // defining what those fake color classes actually paint, since these
    // fixtures don't load the real vendored Tailwind script.
    const fakeTailwindHead = '''
<script>
  window.tailwind = { config: { theme: { extend: { colors: {
    'brand-a': '#010203', 'brand-b': '#040506'
  } } } } };
</script>
<style>
  .text-brand-a { color: rgb(1, 2, 3); }
  .text-brand-b { color: rgb(4, 5, 6); }
</style>
''';

    for (final rootOwnsColour in [false, true]) {
      test(
        'a graphic wrapper does not replace visible text; '
        'root override=$rootOwnsColour',
        () async {
          await loadHtml('''
<html><body style="color: rgb(1, 2, 3)">
<div id="x" ${rootOwnsColour ? 'style="color: rgb(7, 8, 9)"' : ''}>
  <div style="color: rgb(90, 91, 92)">
    <svg><rect width="30" height="20"></rect></svg>
  </div>
  <span class="text-inherit">Actual label</span>
</div></body></html>
''');
          final actual = await captureComputedStyle(page, '#x');
          expect(
            actual!['color'],
            rootOwnsColour ? 'rgb(7, 8, 9)' : 'rgb(1, 2, 3)',
          );
        },
      );
    }

    for (final hidden in [
      'opacity: 0',
      'visibility: hidden',
      'position: absolute; clip: rect(0px, 0px, 0px, 0px)',
    ]) {
      test('an unpainted text source is ignored ($hidden)', () async {
        await loadHtml('''
<html><body style="color: rgb(1, 2, 3)"><div id="x">
  <span style="color: rgb(90, 91, 92); $hidden">Hidden label</span>
  <span class="text-inherit">Actual label</span>
</div></body></html>
''');
        final actual = await captureComputedStyle(page, '#x');
        expect(actual!['color'], 'rgb(1, 2, 3)');
      });
    }

    test(
      'screen-reader-only text does not create painted text fields',
      () async {
        await loadHtml('''
<html><body><div id="x">
  <svg><rect width="30" height="20"></rect></svg>
  <span style="position: absolute; width: 1px; height: 1px;
    overflow: hidden; clip: rect(0px, 0px, 0px, 0px)">Accessible label</span>
</div></body></html>
''');
        final actual = await captureComputedStyle(page, '#x');
        for (final field in [
          'color',
          'fontFamily',
          'fontSize',
          'fontWeight',
          'lineHeight',
          'letterSpacing',
        ]) {
          expect(actual![field], isNull, reason: field);
        }
      },
    );

    test(
      'an early bare text node wins before a later colour override',
      () async {
        await loadHtml('''
<html><body style="color: rgb(1, 2, 3)"><div id="x">
  <span>Primary label</span>
  <span style="color: rgb(7, 8, 9)">Secondary label</span>
</div></body></html>
''');
        final actual = await captureComputedStyle(page, '#x');
        expect(actual!['color'], 'rgb(1, 2, 3)');
      },
    );

    for (final clips in [true, false]) {
      test('zero-width clipping is respected; clips=$clips', () async {
        await loadHtml('''
<html><body style="color: rgb(1, 2, 3)"><div id="x">
  <div style="width: 0; height: 20px; white-space: nowrap;
    overflow: ${clips ? 'hidden' : 'visible'}; color: rgb(90, 91, 92)">Action</div>
  <span class="text-inherit">Actual label</span>
</div></body></html>
''');
        final actual = await captureComputedStyle(page, '#x');
        expect(actual!['color'], clips ? 'rgb(1, 2, 3)' : 'rgb(90, 91, 92)');
      });
    }

    test(
      'a placeholder uses its input line box when its own is normal',
      () async {
        await loadHtml('''
<html><head><style>input::placeholder { line-height: normal; }</style></head>
<body><input id="x" placeholder="Hint" style="line-height: 28px"></body></html>
''');
        final actual = await captureComputedStyle(page, '#x');
        expect(actual!['lineHeight'], '28px');
      },
    );

    for (final metadata in ['', '<title>Border</title><desc>Outline</desc>']) {
      test(
        'a decorative SVG does not supply text colour ($metadata)',
        () async {
          await loadHtml('''
<html><body style="color: rgb(1, 2, 3)">
<div id="x">
  <svg style="color: rgb(90, 91, 92)" aria-hidden="true">
    $metadata
    <rect width="30" height="20" fill="none" stroke="currentColor"></rect>
  </svg>
  <span class="text-inherit">Actual label</span>
</div>
</body></html>
''');
          final result = await captureComputedStyle(page, '#x');
          expect(result!['color'], 'rgb(1, 2, 3)');
        },
        skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
      );
    }

    test(
      'a real text colour override after a decorative SVG still wins',
      () async {
        await loadHtml('''
<html><body style="color: rgb(1, 2, 3)">
<div id="x">
  <svg style="color: rgb(90, 91, 92)"><rect width="30" height="20"></rect></svg>
  <span style="color: rgb(7, 8, 9)">Actual override</span>
</div>
</body></html>
''');
        final result = await captureComputedStyle(page, '#x');
        expect(result!['color'], 'rgb(7, 8, 9)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test('SVG containing actual text remains a text source', () async {
      await loadHtml('''
<html><body style="color: rgb(1, 2, 3)">
<div id="x">
  <svg style="color: rgb(4, 5, 6)">
    <text x="0" y="20" fill="currentColor">Visible SVG text</text>
  </svg>
  <span class="text-inherit">Later label</span>
</div>
</body></html>
''');
      final result = await captureComputedStyle(page, '#x');
      expect(result!['color'], 'rgb(4, 5, 6)');
    }, skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null);

    test(
      'root declares its own color class — reads root directly, not a '
      'nested sub-component that declares a different one (mirrors '
      "card's own header/footer-override shape)",
      () async {
        await loadHtml('''
<html><head>$fakeTailwindHead</head><body>
<div data-parity-key="k" style="background-color: rgb(9, 9, 9);">
  <div class="text-brand-a" style="background-color: rgb(7, 7, 7);">
    <button class="text-brand-b">nested action</button>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['color'], 'rgb(1, 2, 3)');
        // Matched node itself paints fill — chrome walk stays here
        // (#4872), so the nested button's fill never wins.
        expect(result['backgroundColor'], 'rgb(7, 7, 7)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'root declares no color of its own — walks its subtree for the '
      "first descendant that does (mirrors dialog's own "
      'unrelated-trigger shape, corrected)',
      () async {
        await loadHtml('''
<html><head>$fakeTailwindHead</head><body>
<div data-parity-key="k">
  <div style="background-color: rgb(9, 9, 9);">
    <div class="text-brand-a">wrapper-declared text</div>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['color'], 'rgb(1, 2, 3)');
        // Matched node itself paints fill — chrome walk stays here.
        expect(result['backgroundColor'], 'rgb(9, 9, 9)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a bare text-inherit leaf found first wins over a later element '
      'that declares its own color — does not keep walking past it '
      "looking for a declaring candidate (mirrors scaffold's own "
      'title-then-status-text shape; regressed during development before '
      'this bare-leaf candidate type existed)',
      () async {
        await loadHtml('''
<html><head>$fakeTailwindHead</head><body>
<div class="text-brand-a">
  <div data-parity-key="k">
    <div>
      <span class="text-inherit">first bare leaf</span>
      <div class="text-brand-b">later, locally-declaring text</div>
    </div>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        // Ambient value from the outer `.text-brand-a` — not `.text-brand-b`.
        expect(result!['color'], 'rgb(1, 2, 3)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'an empty field reports its ::placeholder colour, not the value colour',
      () async {
        // The exact shape the Web TextField emits: a native input carrying a
        // `placeholder` attribute, with the placeholder colour stated only on
        // the pseudo-element. Before the pseudo was read, this reported
        // `rgb(1, 2, 3)` — the colour of the value nobody has typed — while
        // the Flutter twin reported the placeholder's own colour, so the two
        // diverged on every text input while painting the same thing.
        await loadHtml('''
<html><head><style>
  #f::placeholder { color: rgb(90, 91, 92); }
</style></head><body>
<div data-parity-key="k">
  <input id="f" placeholder="Enter your email" style="color: rgb(1,2,3);">
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['color'], 'rgb(90, 91, 92)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a field holding a value reports the value colour, not ::placeholder',
      () async {
        // The pseudo is only what is on screen while the field is empty.
        // Reading it for a filled field would report a colour nothing draws.
        await loadHtml('''
<html><head><style>
  #f::placeholder { color: rgb(90, 91, 92); }
</style></head><body>
<div data-parity-key="k">
  <input id="f" placeholder="Enter your email" value="typed"
    style="color: rgb(1,2,3);">
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['color'], 'rgb(1, 2, 3)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a placeholder-showing input wins over a later colour-declaring node',
      () async {
        // The input carries its own colour class AND shows a placeholder.
        // The class describes the value; the glyphs on screen are the
        // placeholder's. The pseudo has to be checked before the generic
        // candidate test or the walk reports the wrong one.
        await loadHtml('''
<html><head>$fakeTailwindHead<style>
  #f::placeholder { color: rgb(90, 91, 92); }
</style></head><body>
<div data-parity-key="k">
  <div>
    <input id="f" class="text-brand-a" placeholder="hint">
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['color'], 'rgb(90, 91, 92)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'unpainted wrapper walks to the single chrome child (Range shape)',
      () async {
        await loadHtml('''
<html><body>
<div data-parity-key="k">
  <div style="width: 800px;">
    <div style="background-color: rgb(77, 78, 81); border-radius: 9999px;
      height: 8px;">track</div>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['backgroundColor'], 'rgb(77, 78, 81)');
        expect(result['borderTopLeftRadius'], '9999px');
        expect(result['widthPx'], 800);
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'outline-only wrapper is not chrome — walk reaches the inner fill '
      '(SwitchField Clickable shape)',
      () async {
        await loadHtml('''
<html><body>
<div data-parity-key="k">
  <div style="outline: 2px solid rgb(1, 2, 3); border-radius: 4px;">
    <div style="background-color: rgb(10, 20, 30); border-radius: 9999px;
      padding: 2px;">toggle</div>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['backgroundColor'], 'rgb(10, 20, 30)');
        expect(result['paddingTop'], '2px');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'unpainted padded wrapper with no chrome child reports 0 padding '
      '(Text example column shape)',
      () async {
        await loadHtml('''
<html><body>
<div data-parity-key="k">
  <div style="padding: 16px;">
    <span>Display L</span>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['paddingTop'], '0px');
        expect(result['backgroundColor'], 'rgba(0, 0, 0, 0)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'two chrome siblings refuse the walk — keep the wrapper '
      '(ThemeController shape)',
      () async {
        await loadHtml('''
<html><body>
<div data-parity-key="k">
  <div>
    <div style="background-color: rgb(1, 0, 0);">a</div>
    <div style="background-color: rgb(0, 1, 0);">b</div>
  </div>
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['backgroundColor'], 'rgba(0, 0, 0, 0)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'outlineStyle is captured so a drawn outline can be told from a bare one',
      () async {
        // A plain div with no styling reports `3px` here: `outline-width`
        // initialises to `medium`. Without the style alongside it, that
        // number said every component had a 3px outline at rest.
        await loadHtml('''
<html><body>
<div data-parity-key="k"><div id="x">no outline anywhere</div></div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['outlineWidth'], '0px');
        expect(result['outlineStyle'], 'none');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'an empty placeholder attribute is not treated as showing one',
      () async {
        // `placeholder=""` renders nothing, so the pseudo is not what is on
        // screen — the field is blank and its own colour is the honest answer.
        await loadHtml('''
<html><head><style>
  #f::placeholder { color: rgb(90, 91, 92); }
</style></head><body>
<div data-parity-key="k">
  <input id="f" placeholder="" style="color: rgb(1,2,3);">
</div>
</body></html>
''');
        final result = await captureComputedStyle(
          page,
          '[data-parity-key="k"] > *',
        );
        expect(result!['color'], 'rgb(1, 2, 3)');
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );
  });
}

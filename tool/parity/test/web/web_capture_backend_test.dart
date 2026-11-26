import 'dart:io';
import 'dart:typed_data';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' show Browser;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/manifest/capture_probes.dart';
import '../../src/manifest/surface_marker_registry.dart';
import '../../src/model/capture_surface.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/network_image_fixture.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/web_capture_backend.dart';

/// The typography tier the harness pins every page to (see
/// `offline_tailwind_harness_axes_test.dart`).
const _kDesktopPin = 'data-coui-typography-tier="desktop"';

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

MatrixEntry _buttonEntry({
  ParityTheme theme = ParityTheme.light,
  CoreSurfaceStyleId surfaceStyle = CoreSurfaceStyleId.defaultStyle,
}) {
  final key = 'button-primary-${theme.name}-${surfaceStyle.name}';
  return MatrixEntry(
    component: 'button',
    variant: 'primary',
    theme: theme,
    surfaceStyle: surfaceStyle,
    tier: ParityTier.t1,
    probes: [rootProbeSpec(key: key, flutterClassName: 'Button')],
  );
}

/// A default-variant, light-theme, default-surface-style entry for
/// [component] — the shape every capture-width contract test below needs,
/// only [component]/[flutterClassName] varying between them.
MatrixEntry _defaultEntry(String component, String flutterClassName) {
  final key = '$component-default-light-defaultStyle';
  return MatrixEntry(
    component: component,
    variant: 'default',
    theme: ParityTheme.light,
    surfaceStyle: CoreSurfaceStyleId.defaultStyle,
    tier: ParityTier.t1,
    probes: captureProbes(
      key: key,
      component: component,
      variant: 'default',
      flutterClassName: flutterClassName,
    ),
  );
}

void main() {
  test('both engines share the opaque 400 by 300 grey image fixture', () {
    final image = img.decodePng(loadParityNetworkImageBytes())!;
    expect((image.width, image.height), (400, 300));
    for (final point in [(0, 0), (200, 150), (399, 299)]) {
      final pixel = image.getPixel(point.$1, point.$2);
      expect([pixel.r, pixel.g, pixel.b, pixel.a], [158, 158, 158, 255]);
    }
  });

  group('renderCaptureBodyHtml', () {
    test('wraps the preview in a data-parity-key div under CoUIWeb', () async {
      final entry = _buttonEntry();
      final html = await renderCaptureBodyHtml(entry);
      expect(html, contains('data-parity-key="${entry.key}"'));
      expect(html, contains('coui-root'));
      // The reset from docsContentTheme() must be present — it's what makes
      // native <button> pick up the inherited font instead of the browser
      // UA default (Arial).
      expect(html, contains('font-family: inherit'));
    });

    test(
      'the wrapper is a flex container, so the component is a flex item',
      () async {
        // The docs site lays the example root out as a flex item of
        // `.coui-root`; an `inline-block` wrapper made a block-level root fill
        // the whole width instead (`_kWrapperDisplay` in
        // web_capture_backend.dart).
        final entry = _buttonEntry();
        final html = await renderCaptureBodyHtml(entry);
        final tag = RegExp(
          '<div[^>]*data-parity-key="${RegExp.escape(entry.key)}"[^>]*>',
        ).firstMatch(html)!.group(0)!;
        expect(tag, contains('display: flex'));
        expect(tag, isNot(contains('inline-block')));
        expect(tag, contains('width: ${kCaptureAvailableWidthPx}px'));
      },
    );

    test(
      'throws a clear error for a slug missing from the preview registry',
      () {
        final entry = MatrixEntry(
          component: 'not-a-real-component',
          variant: 'default',
          theme: ParityTheme.light,
          surfaceStyle: CoreSurfaceStyleId.defaultStyle,
          tier: ParityTier.t2,
          probes: [
            rootProbeSpec(key: 'x', flutterClassName: 'X'),
          ],
        );
        expect(() => renderCaptureBodyHtml(entry), throwsStateError);
      },
    );
  });

  group('writeHarnessFile', () {
    late Directory harnessDir;

    setUp(() {
      harnessDir = Directory.systemTemp.createTempSync('parity-harness-');
    });

    tearDown(() {
      harnessDir.deleteSync(recursive: true);
    });

    test('stamps the theme and omits data-coui-style for defaultStyle', () {
      final entry = _buttonEntry();
      final file = writeHarnessFile(
        entry: entry,
        bodyHtml: '<div></div>',
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: '/* stub */',
        fontFaceCss: '',
        iconifyHeadHtml: '',
        harnessDir: harnessDir,
      );
      final html = file.readAsStringSync();
      expect(html, contains('<html data-theme="light" $_kDesktopPin>'));
      // The JS-injected surface-style CSS block is always present (see
      // `offline_tailwind_harness_axes_test.dart`) and legitimately
      // mentions `data-coui-style` as a CSS selector fragment — what must
      // stay absent is the *HTML attribute* on the root tag.
      expect(
        html,
        isNot(contains('<html data-theme="light" data-coui-style')),
      );
    });

    test('stamps data-coui-style for a non-default surface style', () {
      final entry = _buttonEntry(
        theme: ParityTheme.dark,
        surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
      );
      final file = writeHarnessFile(
        entry: entry,
        bodyHtml: '<div></div>',
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: '/* stub */',
        fontFaceCss: '',
        iconifyHeadHtml: '',
        harnessDir: harnessDir,
      );
      final html = file.readAsStringSync();
      expect(
        html,
        contains(
          '<html data-theme="dark" data-coui-style="neoBrutalism" '
          '$_kDesktopPin>',
        ),
      );
    });
  });

  group('captureWebEntry (Chrome required)', () {
    final chromePath = _systemChromePath();
    late Browser browser;
    late Directory harnessDir;

    setUpAll(() async {
      browser = await launchCaptureBrowser(
        width: 800,
        height: 600,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      await browser.close();
    });

    setUp(() {
      harnessDir = Directory.systemTemp.createTempSync('parity-capture-');
    });

    tearDown(() {
      if (harnessDir.existsSync()) harnessDir.deleteSync(recursive: true);
    });

    test(
      'the still image hides the caret while retaining focus styling',
      () async {
        final file = writeHarnessFile(
          entry: _buttonEntry(),
          bodyHtml: '''
<input id="search" style="caret-color: red">
<style>#search:focus { outline-color: green; }</style>
''',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          fontFaceCss: '',
          iconifyHeadHtml: '',
          harnessDir: harnessDir,
        );
        final page = await browser.newPage();
        addTearDown(page.close);
        await page.goto(file.uri.toString());
        final focusStyles = await page.evaluate<List<Object?>>('''
() => {
  const input = document.getElementById('search');
  input.focus();
  const style = getComputedStyle(input);
  return [document.activeElement === input, style.caretColor, style.outlineColor];
}
''');
        expect(focusStyles, [true, 'rgba(0, 0, 0, 0)', 'rgb(0, 128, 0)']);
      },
      skip: chromePath == null ? 'No local Chrome' : null,
    );

    test(
      'a photo decodes from the shared fixture with the page offline',
      () async {
        final result = await captureWebEntry(
          browser: browser,
          entry: _defaultEntry('card-image', 'CardImage'),
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          fontFaceCss: buildLocalFontFaceCss(),
          iconifyHeadHtml: buildLocalIconifyHeadHtml(),
          harnessDir: harnessDir,
          timeoutMs: 5000,
        );
        final image = img.decodePng(result.pngBytes)!;
        final pixel = image.getPixel(image.width ~/ 2, 40);
        expect([pixel.r, pixel.g, pixel.b, pixel.a], [158, 158, 158, 255]);
      },
      skip: chromePath == null ? 'No local Chrome' : null,
    );

    test(
      'captures a non-empty PNG and the root role computed style',
      () async {
        final result = await captureWebEntry(
          browser: browser,
          entry: _buttonEntry(),
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          fontFaceCss: buildLocalFontFaceCss(),
          iconifyHeadHtml: buildLocalIconifyHeadHtml(),
          harnessDir: harnessDir,
        );
        expect(result.pngBytes, isNotEmpty);
        expect(result.chromeVersion, isNotEmpty);
        final root = result.rawPropertyByRole['root'];
        expect(root, isNotNull);
        expect(root!['backgroundColor'], isNot('rgba(0, 0, 0, 0)'));
        expect(root['fontFamily'], contains('Pretendard'));
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'a marker component actually differs under a non-default surface style',
      () async {
        final cardDefault = MatrixEntry(
          component: 'card',
          variant: 'default',
          theme: ParityTheme.light,
          surfaceStyle: CoreSurfaceStyleId.defaultStyle,
          tier: ParityTier.t1,
          probes: [
            rootProbeSpec(
              key: 'card-default-light-defaultStyle',
              flutterClassName: 'Card',
            ),
          ],
        );
        final cardNeoBrutalism = MatrixEntry(
          component: 'card',
          variant: 'default',
          theme: ParityTheme.light,
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          tier: ParityTier.t1,
          probes: [
            rootProbeSpec(
              key: 'card-default-light-neoBrutalism',
              flutterClassName: 'Card',
            ),
          ],
        );
        expect(
          kSurfaceMarkerComponentSlugs,
          contains('card'),
          reason: 'this test assumes card carries the surface marker',
        );

        final themeConfig = ThemeConfig.defaults();
        final vendored = loadVendoredTailwindScript();
        final fontCss = buildLocalFontFaceCss();
        final iconifyHeadHtml = buildLocalIconifyHeadHtml();

        final defaultResult = await captureWebEntry(
          browser: browser,
          entry: cardDefault,
          themeConfig: themeConfig,
          vendoredTailwindScript: vendored,
          fontFaceCss: fontCss,
          iconifyHeadHtml: iconifyHeadHtml,
          harnessDir: harnessDir,
        );
        final neoResult = await captureWebEntry(
          browser: browser,
          entry: cardNeoBrutalism,
          themeConfig: themeConfig,
          vendoredTailwindScript: vendored,
          fontFaceCss: fontCss,
          iconifyHeadHtml: iconifyHeadHtml,
          harnessDir: harnessDir,
        );

        final defaultRoot = defaultResult.rawPropertyByRole['root']!;
        final neoRoot = neoResult.rawPropertyByRole['root']!;
        final changedFields = [
          for (final key in defaultRoot.keys)
            if (defaultRoot[key] != neoRoot[key]) key,
        ];
        expect(
          changedFields,
          isNotEmpty,
          reason:
              'defaultStyle vs neoBrutalism produced byte-identical '
              'computed style — either the surface-style CSS injection '
              'regressed, or this capture missed the marker element '
              'entirely. defaultStyle=$defaultRoot',
        );
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );
  });

  // ═══════════════════════════════════════════════════════════════════
  // #3665 — capture-width contract guards. Each of G0/G1/G2 is a real
  // puppeteer capture (not a string/HTML assertion) so it goes RED if the
  // wrapper's width policy drifts, not just if the wrapper's markup does.
  // ═══════════════════════════════════════════════════════════════════
  group('capture-width contract (#3665, Chrome required)', () {
    final chromePath = _systemChromePath();
    late Browser browser;
    late Directory harnessDir;

    setUpAll(() async {
      browser = await launchCaptureBrowser(
        width: 1600,
        height: 1200,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      await browser.close();
    });

    setUp(() {
      harnessDir = Directory.systemTemp.createTempSync(
        'parity-capture-width-',
      );
    });

    tearDown(() {
      if (harnessDir.existsSync()) harnessDir.deleteSync(recursive: true);
    });

    /// Runs a real capture of [entry] and returns the decoded PNG width —
    /// every G0/G1/G2 assertion below reduces to comparing this against an
    /// expected width, so the actual browser round-trip lives in one place.
    Future<int> capturedWidthPx(
      MatrixEntry entry, {
      int availableWidthPx = kCaptureAvailableWidthPx,
    }) async {
      final result = await captureWebEntry(
        browser: browser,
        entry: entry,
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        fontFaceCss: buildLocalFontFaceCss(),
        iconifyHeadHtml: buildLocalIconifyHeadHtml(),
        harnessDir: harnessDir,
        availableWidthPx: availableWidthPx,
      );
      // A centred preview has a full-width stage and a separately captured
      // capped body. These tests exercise the component's width contract.
      return img.decodePng(result.pngBytes)!.width;
    }

    final skipReason = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

    group('G0 — container-driven (w-full) roots render at the contract '
        'width', () {
      // divider/progress/slider's *default* variant root is a bare `w-full`
      // Tailwind class with no `max-width` cap (unlike responsive-container,
      // G2 below) — the plainest possible case a shrink-to-fit wrapper
      // computes to 0 for and a width-carrying wrapper computes to exactly
      // [kCaptureAvailableWidthPx] for.
      for (final c in const [
        ('divider', 'Divider'),
        ('progress', 'Progress'),
        ('slider', 'Slider'),
      ]) {
        test('${c.$1} PNG width == kCaptureAvailableWidthPx', () async {
          final width = await capturedWidthPx(_defaultEntry(c.$1, c.$2));
          expect(width, kCaptureAvailableWidthPx);
        }, skip: skipReason);
      }
    });

    group('G1 — the wrapper width is a real function of availableWidthPx', () {
      test(
        'divider renders at 400 when given 400, at 800 when given 800',
        () async {
          // Two distinct injected widths, not just kCaptureAvailableWidthPx
          // itself — a wrapper whose width happened to be hard-coded to the
          // literal `'800px'` (never actually reading [availableWidthPx])
          // would still pass a single-width G0-style check. Only a second,
          // *different* width value can catch that.
          final at400 = await capturedWidthPx(
            _defaultEntry('divider', 'Divider'),
            availableWidthPx: 400,
          );
          final at800 = await capturedWidthPx(
            _defaultEntry('divider', 'Divider'),
          );
          expect(at400, 400);
          expect(at800, 800);
        },
        skip: skipReason,
      );
    });

    group('G2 — content-sized invariant + the clamped case', () {
      test(
        'a content-sized component (Button) ignores availableWidthPx',
        () async {
          final at400 = await capturedWidthPx(
            _buttonEntry(),
            availableWidthPx: 400,
          );
          final at800 = await capturedWidthPx(_buttonEntry());
          expect(
            at400,
            at800,
            reason:
                'Button has no w-full class — giving it more available '
                'width must not change its own rendered width, or the '
                'wrapper fix is forcing every component to stretch '
                'instead of only w-full ones.',
          );
        },
        skip: skipReason,
      );

      test(
        'a clamped component (ResponsiveContainer maxWidth=sm/640px) tracks '
        'availableWidthPx below its cap, and clamps to it above',
        () async {
          expect(
            CoreResponsiveContainerMaxWidth.sm.maxWidth,
            640,
            reason:
                'this test hard-codes 640 as the expected capture width — '
                'if `sm` ever stops meaning 640px this assumption needs '
                'updating alongside it.',
          );
          final entry = _defaultEntry(
            'responsive-container',
            'ResponsiveContainer',
          );

          // The "w-full vs content-sized" binary above misses this third
          // category entirely: `w-full` *and* `max-width: 640px` together
          // render at min(availableWidthPx, 640) — neither 0 (the
          // pre-#3665 bug's answer, uniformly) nor a fixed 640 regardless
          // of availableWidthPx.
          //
          // Below the cap (400 < 640) is the discriminating half of this
          // test — a browser's shrink-to-fit width calculation derives an
          // *upper* bound from `max-width` alone even with no definite
          // container width at all (verified: the pre-#3665 wrapper bug,
          // reintroduced locally and reverted, captured this same entry at
          // 640 regardless of which availableWidthPx was requested). Only
          // asserting the above-cap (800 → 640) half would make this test
          // pass whether or not availableWidthPx actually reaches the
          // wrapper — it needs both halves to prove the wrapper is a real
          // function of its input across the whole clamped range, not
          // just bounded by it.
          final belowCap = await capturedWidthPx(entry, availableWidthPx: 400);
          expect(belowCap, 400);

          final aboveCap = await capturedWidthPx(entry);
          expect(aboveCap, 640);
        },
        skip: skipReason,
      );
    });

    group(
      'G3 — a block-level root sizes to its content, as on the docs site',
      () {
        test(
          'a plain-div root (dot-indicator) is narrower than the available '
          'width',
          () async {
            // The wrapper used to be `inline-block`, which made every
            // block-level root fill the whole 800px — 110 default-style cells
            // read `widthPx: web=800` against a docs-site width of 88. A flex
            // item sizes to its content unless it declares a width.
            final width = await capturedWidthPx(
              _defaultEntry('dot-indicator', 'DotIndicator'),
            );
            expect(
              width,
              lessThan(kCaptureAvailableWidthPx),
              reason:
                  'a block-level root filled the wrapper again — the '
                  'wrapper is no longer a flex container '
                  '(web_capture_backend.dart).',
            );
          },
          skip: skipReason,
        );
      },
    );
  });

  group('writeWebCaptureArtifacts', () {
    test('writes <key>.web.png and <key>.web.json with byRole nesting', () {
      final outDir = Directory.systemTemp.createTempSync('parity-artifacts-');
      addTearDown(() => outDir.deleteSync(recursive: true));

      final entry = _buttonEntry();
      writeWebCaptureArtifacts(
        result: WebCaptureResult(
          pngBytes: Uint8List.fromList([1, 2, 3]),
          rawPropertyByRole: {
            'root': {'fontWeight': '400'},
          },
          chromeVersion: 'Chrome/999.0.0.0',
        ),
        entry: entry,
        outDir: outDir,
      );

      final pngFile = File('${outDir.path}/${entry.key}.web.png');
      final jsonFile = File('${outDir.path}/${entry.key}.web.json');
      expect(pngFile.existsSync(), isTrue);
      expect(pngFile.readAsBytesSync(), [1, 2, 3]);
      expect(jsonFile.readAsStringSync(), contains('"chromeVersion"'));
      expect(jsonFile.readAsStringSync(), contains('"byRole"'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // #3665 — integer-geometry cross-platform anchor. Locks in the exact
  // Chrome capture width for the same label
  // `integer_capture_test.dart` (coui_flutter) hard-codes as its own
  // expected value (105) — that constant is only a real cross-platform
  // target if *this* side is independently verified, not assumed.
  //
  // "Place Order" at the Button label weight (500) is rounded to a 105px PNG
  // by Chrome's `element.screenshot()` (measured by this test in CI).
  // Flutter's natural width is 105.129px: its naive ceil is 106 and its
  // round-to-nearest is 105, so the label still splits the two roundings
  // (see the twin comment in `integer_capture_test.dart`).
  // ═══════════════════════════════════════════════════════════════════
  group('integer-geometry cross-platform anchor (#3665, Chrome required)', () {
    final chromePath = _systemChromePath();
    late Browser browser;

    setUpAll(() async {
      browser = await launchCaptureBrowser(
        width: 1600,
        height: 1200,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      await browser.close();
    });

    test(
      'Chrome rounds "Place Order" Button to 105px, not 106 '
      '(the naive Flutter ceil)',
      () async {
        // Not routed through kWebPreviewRegistry/renderCaptureBodyHtml —
        // "Place Order" is a synthetic probe label picked to fall on
        // the fractional-below-.5 side of a real intrinsic width, not a
        // registered catalog example, so this composes the same
        // CoUIWeb + width-contract wrapper renderCaptureBodyHtml uses,
        // directly.
        Component build(BuildContext context) => .fragment([
          Style(styles: docsContentTheme().styles),
          CoUIWeb(
            theme: .coui,
            child: div(
              [
                Button(
                  onPressed: () {},
                  child: const Text('Place Order'),
                ),
              ],
              styles: const Styles(
                raw: {
                  'display': 'inline-block',
                  'width': kCaptureAvailableWidthCss,
                },
              ),
              attributes: const {'data-parity-key': 'rounding-anchor'},
            ),
          ),
        ]);

        final bodyHtml = await renderComponentBodyHtml(
          _BuildContextlessProbe(build),
        );
        final harnessDir = Directory.systemTemp.createTempSync(
          'parity-rounding-anchor-',
        );
        addTearDown(() => harnessDir.deleteSync(recursive: true));
        final html = buildOfflineTailwindHarnessHtml(
          bodyHtml: bodyHtml,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml:
              '<style>${buildLocalFontFaceCss()}</style>\n'
              '${buildLocalIconifyHeadHtml()}',
        );
        final file = File(p.join(harnessDir.path, 'anchor.html'))
          ..writeAsStringSync(html);

        final page = await browser.newPage();
        addTearDown(page.close);
        await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
        await page.evaluate<void>(
          '() => document.fonts ? document.fonts.ready.then(() => {}) '
          ': Promise.resolve()',
        );
        final element = await page.$('[data-parity-key="rounding-anchor"] > *');
        final pngBytes = Uint8List.fromList(
          await element.screenshot(format: .png),
        );
        final width = img.decodePng(pngBytes)!.width;

        expect(
          width,
          105,
          reason:
              'if this ever fails, re-run the 15-minute measurement '
              "(this file's + integer_capture_test.dart's top comments) "
              'against real captures — Pretendard metrics changed, or '
              "Chrome's own rounding behavior did, and the "
              'cross-platform target (105) needs updating in both places.',
        );
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );
  });
}

/// A minimal [StatelessComponent] whose sole purpose is handing an actual
/// `BuildContext` to [_build] — mirrors `web_capture_backend.dart`'s own
/// `_BuildContextlessWrapper` (private to that file, so this test needs
/// its own copy).
class _BuildContextlessProbe extends StatelessComponent {
  const _BuildContextlessProbe(this._build);
  final Component Function(BuildContext context) _build;

  @override
  Component build(BuildContext context) => _build(context);
}

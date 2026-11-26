// The frost and the body shade of a glass surface, judged in a real browser.
//
// `surface_finish_css_test.dart` reads the stylesheet as text. A stylesheet is
// read by a browser that substitutes custom properties into a list, fetches
// an SVG document out of a data URL, runs the filters on the backdrop and
// then applies a preference that takes them away again — each of which can
// fail while the text is right. So the claim is made in pixels.
//
// ## Everything here drives the shipped code
//
// The page carries the compiled host (`surface_mode_entry.dart`) and the
// stylesheet comes from `ThemeConfig`. The expected values are never computed
// from a copy of the arithmetic: they are `CoreSurfaceFrost.mix` and
// `CoreSurfaceBodyShade.shade`, the statements the Flutter seat is tested
// against too, applied to pixels *measured on the same page without the
// term*.
//
// ## What each verdict is
//
//   frost mix        a heavy blur of a striped backdrop mixed over the
//                    lightly blurred one at the opacity the tuning states:
//                    the pixel measured with the frost equals `mix(cloud,
//                    copy, opacity)`, where `cloud` is measured at opacity 1
//                    and `copy` without the frost. Linear, so the dimming
//                    that follows it in the list does not enter.
//   body shade       bands of grey and colour behind the panel: the pixel
//                    measured with the shade equals `shade(strength, pixel
//                    measured without it)`.
//   per mode         the dark share is the one that draws in a dark page,
//                    and a shade stated for the dark palette alone leaves a
//                    light page as it was.
//   plain surfaces   more contrast and forced colours take both terms away,
//                    and the surface then draws what a tuning that never
//                    stated them draws; reduced transparency takes the whole
//                    list away.
//   host             the document-level runtime still bends a surface whose
//                    list carries the stylesheet's own filters, and follows
//                    the preference when it flips.
//   ring             what the Web offers a term that is confined to a contour
//                    and keyed on luminance (the rim terms that were not
//                    built): a ring laid beside the glass turns the luminance
//                    behind it upside down, pixel for pixel, and a ring laid
//                    inside the glass sees nothing of the page.
//
// A run with no Chrome on the machine is skipped, not zeroed.
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:puppeteer/protocol/emulation.dart' as protocol;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/panel_pixels.dart';

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

const _kEntryPath = 'tool/parity/src/web/surface_mode_entry.dart';

const _kViewportWidth = 400;
const _kViewportHeight = 300;

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

/// The columns that sit at the middle of a stripe of the backdrop, inside the
/// frost panel and far enough from its edges that the mirrored edge of the
/// blur does not reach them (the stripes are 12px wide).
const List<int> _kStripeColumns = [66, 78, 90, 102, 114, 126];

/// The row the stripes are read at.
const int _kStripeRow = 150;

/// The bands the shade is read on: the centre of each of the colours below
/// the first, which sits above the panel.
const List<({String name, int y})> _kBands = [
  (name: 'dark grey', y: 45),
  (name: 'mid grey', y: 75),
  (name: 'light grey', y: 105),
  (name: 'white', y: 135),
  (name: 'orange', y: 165),
  (name: 'red', y: 195),
  (name: 'green', y: 225),
  (name: 'blue', y: 255),
];

/// The column the bands are read at: the middle of the shade panel.
const int _kBandColumn = 300;

/// Two panels over two backdrops, and nothing else.
///
/// The panels are positioned and cleared **inline**: the stylesheet states
/// `position` and `background-color` on a marked surface at a specificity no
/// class of the page's own reaches, so a class here would leave the panel in
/// the flow with its fill on. The fill is transparent so the pixels read are
/// the backdrop filter's and not a fill composited over it; the preset test
/// takes it off again to read the surface as an app draws it.
/// `--coui-surface-rgb` is written because every component publishes it.
/// Representative user agents. Only the token that tells Blink from the rest
/// decides (`surfaceRefractionBrowserSupported`); the strings are what real
/// browsers send.
const String _kChromeUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36';
const String _kEdgeUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36 Edg/156.0.0.0';
const String _kSafariUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
    '(KHTML, like Gecko) Version/27.0 Safari/605.1.15';
const String _kFirefoxUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:140.0) Gecko/20100101 '
    'Firefox/140.0';
const String _kChromeOnIosUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 19_0 like Mac OS X) '
    'AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/156.0.0.0 '
    'Mobile/15E148 Safari/604.1';

const String _kBodyHtml =
    '''
<style>
  body { margin: 0; width: ${_kViewportWidth}px; height: ${_kViewportHeight}px;
         background: #808080; }
  #stripes { position: absolute; left: 0; top: 0; width: 200px; height: 300px;
             background: repeating-linear-gradient(90deg,
               #000 0 12px, #fff 12px 24px); }
  #bands { position: absolute; left: 200px; top: 0; width: 200px;
           height: 300px; }
  .band { height: 30px; }
</style>
<div id="stripes"></div>
<div id="bands">
  <div class="band" style="background:#000"></div>
  <div class="band" style="background:#404040"></div>
  <div class="band" style="background:#808080"></div>
  <div class="band" style="background:#c0c0c0"></div>
  <div class="band" style="background:#fff"></div>
  <div class="band" style="background:#ff8000"></div>
  <div class="band" style="background:#f00"></div>
  <div class="band" style="background:#0f0"></div>
  <div class="band" style="background:#00f"></div>
  <div class="band" style="background:#00c8c8"></div>
</div>
<div id="pf" data-clear class="coui-surface coui-surface-functional"
     style="position: absolute; left: 20px; top: 20px; width: 160px;
            height: 260px; border-radius: 24px; background-color: transparent;
            --coui-surface-rgb: var(--coui-surface);">
  <div id="nested" class="coui-surface coui-surface-functional"
       style="position: absolute; left: 20px; top: 20px; width: 80px;
              height: 60px; --coui-surface-rgb: var(--coui-surface);"></div>
</div>
<div id="ps" data-clear class="coui-surface coui-surface-functional"
     style="position: absolute; left: 220px; top: 20px; width: 160px;
            height: 260px; border-radius: 24px; background-color: transparent;
            --coui-surface-rgb: var(--coui-surface);"></div>
''';

/// One panel over a smooth ramp from black to white, for the claim that the
/// shade follows luminance pixel by pixel and not band by band.
const String _kGradientHtml =
    '''
<style>
  body { margin: 0; width: ${_kViewportWidth}px; height: ${_kViewportHeight}px;
         background: #808080; }
  #g { position: absolute; inset: 0;
       background: linear-gradient(90deg, #000, #fff); }
</style>
<div id="g"></div>
<div id="pf" class="coui-surface coui-surface-functional"
     style="position: absolute; left: 20px; top: 20px; width: 360px;
            height: 260px; border-radius: 24px; background-color: transparent;
            --coui-surface-rgb: var(--coui-surface);"></div>
''';

/// The greys the ring page lays its glass over, and the left edge of each.
const List<String> _kRingGreys = [
  '#000000',
  '#404040',
  '#808080',
  '#c0c0c0',
  '#ffffff',
];
const List<int> _kRingXs = [10, 90, 170, 250, 330];

/// The rows of the ring page: a ring beside the glass, a ring inside it, and
/// the glass alone to read the backdrop from.
const int _kRingBesideTop = 10;
const int _kRingInsideTop = 90;
const int _kRingControlTop = 170;

/// Squares of flat grey with a glass over each, and a ring of the glass's
/// contour — its own mask, its own `backdrop-filter` that turns the luminance
/// of what is behind it upside down at half contrast about mid-grey — laid in
/// three ways: beside the glass, inside it, and not at all. Under the three a
/// ramp from black to white with one ring beside its glass.
///
/// This is the experiment behind the rim terms that were not built: it says
/// what the Web can and cannot do for a term that is confined to a contour
/// and keyed on the luminance behind it.
String _ringHtml() {
  String cells(int top, String mode) {
    final out = StringBuffer();
    for (var i = 0; i < _kRingGreys.length; i++) {
      final x = _kRingXs[i];
      final box = 'left:${x}px;top:${top}px';
      out.write(
        '<div class="bd" style="$box;background:${_kRingGreys[i]}"></div>',
      );
      switch (mode) {
        case 'beside':
          out
            ..write('<div class="g" style="$box"></div>')
            ..write('<div class="ring" style="$box"></div>');
        case 'inside':
          out
            ..write('<div class="g" style="$box">')
            ..write('<div class="ring" style="left:0;top:0"></div></div>');
        default:
          out.write('<div class="g" style="$box"></div>');
      }
    }

    return out.toString();
  }

  return '''
<style>
  html, body { margin: 0; background: #808080; }
  .bd { position: absolute; width: 60px; height: 60px; }
  .g { position: absolute; width: 60px; height: 60px; border-radius: 14px;
       backdrop-filter: blur(0.6px); }
  .ring, #rampring { position: absolute; box-sizing: border-box;
       padding: 3px; backdrop-filter: grayscale(1) invert(1) contrast(.5);
       -webkit-mask: linear-gradient(#000 0 0) content-box,
                     linear-gradient(#000 0 0);
       -webkit-mask-composite: xor; mask-composite: exclude; }
  .ring { width: 60px; height: 60px; border-radius: 14px; }
  #rampbd, #rampg, #rampring { left: 10px; top: 250px; width: 380px;
       height: 40px; position: absolute; }
  #rampbd { background: linear-gradient(90deg, #000, #fff); }
  #rampg { border-radius: 6px; backdrop-filter: blur(0.6px); }
  #rampring { border-radius: 6px; }
</style>
${cells(_kRingBesideTop, 'beside')}
${cells(_kRingInsideTop, 'inside')}
${cells(_kRingControlTop, 'control')}
<div id="rampbd"></div><div id="rampg"></div><div id="rampring"></div>
''';
}

Future<void> _settle(Page page) async {
  await page.evaluate<void>(
    '() => new Promise(function (done) { requestAnimationFrame(function () '
    '{ requestAnimationFrame(done); }); })',
  );
}

Future<bool> _holds(
  Page page,
  String condition, {
  Duration within = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(within);
  while (DateTime.now().isBefore(deadline)) {
    if (await page.evaluate<bool>('() => !!($condition)')) return true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  return false;
}

String _computedFilter(String id) =>
    "getComputedStyle(document.getElementById('$id')).backdropFilter";

String _inlineFilter(String id) =>
    "document.getElementById('$id').style.backdropFilter";

Future<String> _read(Page page, String expression) async =>
    await page.evaluate<String>('() => String($expression)');

/// The page's `@supports` rules that name an Apple feature: the first-paint
/// query of the glass, as an expression that evaluates to the list of them.
const String _firstPaintQueries =
    '(() => { const out = []; '
    'for (const sheet of document.styleSheets) '
    'for (const rule of sheet.cssRules) '
    'if (rule instanceof CSSSupportsRule '
    "&& rule.conditionText.includes('-apple-')) "
    'out.push(rule); '
    'return out; })()';

/// One channel triple, 0 to 255.
typedef _Rgb = ({int r, int g, int b});

_Rgb _at(img.Image image, int x, int y, {double scale = 1}) {
  final px = image.getPixel((x * scale).round(), (y * scale).round());

  return (r: px.r.toInt(), g: px.g.toInt(), b: px.b.toInt());
}

/// The largest per-channel distance between two pixels.
int _distance(_Rgb a, _Rgb b) => [
  (a.r - b.r).abs(),
  (a.g - b.g).abs(),
  (a.b - b.b).abs(),
].reduce((x, y) => x > y ? x : y);

/// How far a measured pixel may be from the statement and still be the
/// statement. Two levels is the capture path's rounding: each filter stage
/// quantises to 8 bits, and the chain here has three.
const int _kTolerance = 2;

/// The frost the stripes are read through, at [opacity] in both palettes
/// unless [dark] differs.
CoreSurfaceTuning _frostTuning(double opacity, {double? dark}) =>
    CoreSurfaceTuning(
      surfaceBlur: 0.6,
      surfaceFrostBlur: 14,
      surfaceFrostOpacity: opacity,
      surfaceFrostOpacityInDarkMode: dark,
    );

void main() {
  final chromePath = _systemChromePath();
  final skipReason = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

  group('the frost and the body shade of the glass, judged in a browser', () {
    late Browser browser;
    late Directory buildDir;
    late String compiledJs;
    var pageCount = 0;

    setUpAll(() async {
      if (chromePath == null) return;

      buildDir = Directory.systemTemp.createTempSync('surface-finish-');
      final output = p.join(buildDir.path, 'host.js');
      final result = Process.runSync('dart', [
        'compile',
        'js',
        '-O2',
        '-o',
        output,
        _kEntryPath,
      ]);
      expect(
        result.exitCode,
        0,
        reason:
            'compiling the shipped host failed:\n'
            '${result.stdout}${result.stderr}',
      );
      compiledJs = File(output).readAsStringSync();

      browser = await launchCaptureBrowser(
        width: _kViewportWidth,
        height: _kViewportHeight,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      if (chromePath == null) return;
      await browser.close();
      buildDir.deleteSync(recursive: true);
    });

    /// A page with [tuning] stated for the glass, in [theme], settled.
    Future<Page> open(
      CoreSurfaceTuning tuning, {
      String theme = 'light',
      String bodyHtml = _kBodyHtml,
      String headHtml = '',
      double density = 1,
      String? userAgent,
      String Function(String html)? transform,
    }) async {
      final page = await browser.newPage();
      // Before the page loads: the browser build reads the user agent once, at
      // module start.
      if (userAgent != null) await page.setUserAgent(userAgent);
      if (density != 1) {
        await page.setViewport(
          DeviceViewport(
            width: _kViewportWidth,
            height: _kViewportHeight,
            deviceScaleFactor: density,
          ),
        );
      }
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '$bodyHtml<script>$compiledJs</script>',
        themeConfig: ThemeConfig.from(
          CouiColorPresets.source,
          surfaceTunings: {_glass: tuning},
        ),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        theme: theme,
        surfaceStyleId: _glass.name,
        additionalHeadHtml: headHtml,
      );
      final file = File(p.join(buildDir.path, 'page-${pageCount++}.html'))
        ..writeAsStringSync(transform == null ? html : transform(html));
      await page.goto(Uri.file(file.path).toString(), wait: Until.load);
      await _settle(page);

      return page;
    }

    Future<img.Image> shoot(Page page, {double density = 1}) async {
      final bytes = await page.screenshot(
        clip: const Rectangle(0, 0, _kViewportWidth, _kViewportHeight),
      );
      final shot = img.decodePng(bytes)!;
      expect(
        shot.width,
        (_kViewportWidth * density).round(),
        reason: 'the capture is not at the density the page was opened at',
      );

      return shot;
    }

    Future<img.Image> shotOf(
      CoreSurfaceTuning tuning, {
      String theme = 'light',
      double density = 1,
    }) async {
      final page = await open(tuning, theme: theme, density: density);
      final shot = await shoot(page, density: density);
      await page.close();

      return shot;
    }

    Future<void> emulate(Page page, Map<String, String> features) =>
        page.devTools.emulation.setEmulatedMedia(
          features: [
            for (final entry in features.entries)
              protocol.MediaFeature(name: entry.key, value: entry.value),
          ],
        );

    Future<void> install(Page page) async {
      await page.evaluate<void>('() => window.couiInstallSurfaceHost()');
      await _settle(page);
    }

    // ------------------------------------------------------------------
    // The frost
    // ------------------------------------------------------------------

    for (final theme in ['light', 'dark']) {
      test(
        'the frost mixes a heavy blur over the lightly blurred backdrop at the '
        '$theme share',
        () async {
          // Different shares per mode, so a page that read the other
          // palette's share fails here.
          const light = 0.73;
          const dark = 0.85;
          final share = theme == 'dark' ? dark : light;

          final copy = await shotOf(
            const CoreSurfaceTuning(surfaceBlur: 0.6),
            theme: theme,
          );
          final cloud = await shotOf(_frostTuning(1), theme: theme);
          final mixed = await shotOf(
            _frostTuning(light, dark: dark),
            theme: theme,
          );

          var worst = 0;
          for (final x in _kStripeColumns) {
            final c = _at(copy, x, _kStripeRow);
            final k = _at(cloud, x, _kStripeRow);
            final m = _at(mixed, x, _kStripeRow);
            final want = (
              r: CoreSurfaceFrost.mix(
                cloud: k.r.toDouble(),
                copy: c.r.toDouble(),
                opacity: share,
              ).round(),
              g: CoreSurfaceFrost.mix(
                cloud: k.g.toDouble(),
                copy: c.g.toDouble(),
                opacity: share,
              ).round(),
              b: CoreSurfaceFrost.mix(
                cloud: k.b.toDouble(),
                copy: c.b.toDouble(),
                opacity: share,
              ).round(),
            );
            final off = _distance(m, want);
            if (off > worst) worst = off;
            expect(
              off,
              lessThanOrEqualTo(_kTolerance),
              reason:
                  '$theme x=$x copy=$c cloud=$k measured=$m want=$want '
                  '(share $share)',
            );
          }
          stdout.writeln('J3-frost $theme share=$share worst=$worst');

          // The premises, so a tolerance that is satisfied by every page is
          // not mistaken for a verdict.
          final dim = _at(copy, 78, _kStripeRow); // a black stripe
          final bright = _at(copy, 90, _kStripeRow); // a white stripe
          expect(
            bright.r - dim.r,
            greaterThan(100),
            reason: 'the copy keeps the stripes sharp',
          );
          final cloudSpread =
              (_at(cloud, 90, _kStripeRow).r - _at(cloud, 78, _kStripeRow).r)
                  .abs();
          expect(
            cloudSpread,
            lessThan(6),
            reason: 'the cloud has no stripes left in it',
          );
        },
        skip: skipReason,
      );
    }

    test(
      'the dark share is not the light one',
      () async {
        final light = await shotOf(_frostTuning(0.73, dark: 0.85));
        final lightAgain = await shotOf(_frostTuning(0.73));
        final dark = await shotOf(
          _frostTuning(0.73, dark: 0.85),
          theme: 'dark',
        );
        final darkLightShare = await shotOf(_frostTuning(0.73), theme: 'dark');

        // A dark share the page does not use is no statement in light...
        expect(
          diffRatio(light, lightAgain),
          lessThan(kUnchangedRatioCeiling),
        );
        // ...and a statement in dark.
        expect(
          diffRatio(dark, darkLightShare),
          greaterThan(kMovedRatioFloor),
          reason: 'the dark palette ignored its own share',
        );
      },
      skip: skipReason,
    );

    test(
      'the frost and the shade draw the same at twice the pixel density',
      () async {
        const density = 2.0;
        const tuning = CoreSurfaceTuning(
          surfaceBlur: 0.6,
          surfaceFrostBlur: 14,
          surfaceFrostOpacity: 0.73,
          surfaceBodyShade: 0.4,
        );
        final one = await shotOf(tuning);
        final two = await shotOf(tuning, density: density);

        var worst = 0;
        for (final x in _kStripeColumns) {
          final a = _at(one, x, _kStripeRow);
          final b = _at(two, x, _kStripeRow, scale: density);
          worst = [worst, _distance(a, b)].reduce((m, d) => m > d ? m : d);
          expect(
            _distance(a, b),
            lessThanOrEqualTo(_kTolerance + 2),
            reason: 'x=$x',
          );
        }
        for (final band in _kBands) {
          final a = _at(one, _kBandColumn, band.y);
          final b = _at(two, _kBandColumn, band.y, scale: density);
          worst = [worst, _distance(a, b)].reduce((m, d) => m > d ? m : d);
          expect(
            _distance(a, b),
            lessThanOrEqualTo(_kTolerance + 2),
            reason: band.name,
          );
        }
        stdout.writeln('J3-density worst=$worst');
      },
      skip: skipReason,
    );

    // ------------------------------------------------------------------
    // The body shade
    // ------------------------------------------------------------------

    for (final theme in ['light', 'dark']) {
      test(
        'the body shade darkens each pixel by its own luminance ($theme)',
        () async {
          const strength = 0.5;
          final plain = await shotOf(
            const CoreSurfaceTuning(surfaceBlur: 0.6),
            theme: theme,
          );
          final shaded = await shotOf(
            const CoreSurfaceTuning(
              surfaceBlur: 0.6,
              surfaceBodyShade: strength,
            ),
            theme: theme,
          );

          var worst = 0;
          for (final band in _kBands) {
            final before = _at(plain, _kBandColumn, band.y);
            final after = _at(shaded, _kBandColumn, band.y);
            final want = CoreSurfaceBodyShade.shade(
              strength: strength,
              red: before.r / 255,
              green: before.g / 255,
              blue: before.b / 255,
            );
            final expected = (
              r: (want.red * 255).round(),
              g: (want.green * 255).round(),
              b: (want.blue * 255).round(),
            );
            final off = _distance(after, expected);
            if (off > worst) worst = off;
            expect(
              off,
              lessThanOrEqualTo(_kTolerance),
              reason:
                  '$theme ${band.name}: before=$before after=$after '
                  'want=$expected',
            );
          }
          stdout.writeln('J3-shade $theme strength=$strength worst=$worst');

          // Not a no-op, and keyed on luminance: the brightest band loses
          // far more than the darkest.
          final bright = _kBands.firstWhere((band) => band.name == 'white');
          final dim = _kBands.firstWhere((band) => band.name == 'dark grey');
          int lost(_Rgb before, _Rgb after) =>
              (before.r + before.g + before.b) - (after.r + after.g + after.b);
          final brightLoss = lost(
            _at(plain, _kBandColumn, bright.y),
            _at(shaded, _kBandColumn, bright.y),
          );
          final dimLoss = lost(
            _at(plain, _kBandColumn, dim.y),
            _at(shaded, _kBandColumn, dim.y),
          );
          expect(brightLoss, greaterThan(60), reason: 'white barely moved');
          expect(dimLoss, lessThan(brightLoss ~/ 4));
        },
        skip: skipReason,
      );
    }

    test(
      'a shade stated for the dark palette alone leaves a light page alone',
      () async {
        const plain = CoreSurfaceTuning(surfaceBlur: 0.6);
        const darkOnly = CoreSurfaceTuning(
          surfaceBlur: 0.6,
          surfaceBodyShadeInDarkMode: 0.5,
        );

        final lightPlain = await shotOf(plain);
        final lightDarkOnly = await shotOf(darkOnly);
        final darkPlain = await shotOf(plain, theme: 'dark');
        final darkDarkOnly = await shotOf(darkOnly, theme: 'dark');

        expect(
          diffRatio(lightPlain, lightDarkOnly),
          lessThan(kUnchangedRatioCeiling),
        );
        expect(
          diffRatio(darkPlain, darkDarkOnly),
          greaterThan(kMovedRatioFloor),
        );
      },
      skip: skipReason,
    );

    test(
      'the body shade follows a smooth gradient pixel by pixel',
      () async {
        const strength = 0.6;
        Future<img.Image> ramp(CoreSurfaceTuning tuning) async {
          final page = await open(tuning, bodyHtml: _kGradientHtml);
          final shot = await shoot(page);
          await page.close();

          return shot;
        }

        final plain = await ramp(const CoreSurfaceTuning(surfaceBlur: 0.6));
        final shaded = await ramp(
          const CoreSurfaceTuning(surfaceBlur: 0.6, surfaceBodyShade: strength),
        );

        var worst = 0;
        for (var x = 60; x <= 340; x += 20) {
          final before = _at(plain, x, 150);
          final after = _at(shaded, x, 150);
          final want = CoreSurfaceBodyShade.shade(
            strength: strength,
            red: before.r / 255,
            green: before.g / 255,
            blue: before.b / 255,
          );
          final expected = (
            r: (want.red * 255).round(),
            g: (want.green * 255).round(),
            b: (want.blue * 255).round(),
          );
          final off = _distance(after, expected);
          if (off > worst) worst = off;
          expect(
            off,
            lessThanOrEqualTo(_kTolerance),
            reason: 'x=$x before=$before after=$after want=$expected',
          );
        }
        stdout.writeln('J3-gradient shade strength=$strength worst=$worst');
        // The ramp really is a ramp, and the shade really bends it: a
        // quadratic pull leaves the dark end and takes the bright one.
        expect(
          _at(plain, 340, 150).r - _at(plain, 60, 150).r,
          greaterThan(150),
        );
        expect(
          _at(plain, 340, 150).r - _at(shaded, 340, 150).r,
          greaterThan(60),
        );
        expect(_at(plain, 60, 150).r - _at(shaded, 60, 150).r, lessThan(6));
      },
      skip: skipReason,
    );

    // ------------------------------------------------------------------
    // What takes them away
    // ------------------------------------------------------------------

    const finished = CoreSurfaceTuning(
      surfaceBlur: 0.6,
      surfaceFrostBlur: 14,
      surfaceFrostOpacity: 0.73,
      surfaceBodyShade: 0.4,
    );
    const unfinished = CoreSurfaceTuning(surfaceBlur: 0.6);

    for (final media in {
      'more contrast': {'prefers-contrast': 'more'},
      'forced colours': {'forced-colors': 'active'},
    }.entries) {
      test(
        '${media.key} takes both terms away and leaves the rest of the glass',
        () async {
          final page = await open(finished);
          final before = await _read(page, _computedFilter('ps'));
          expect(
            before,
            contains('url('),
            reason: 'the premise: the terms are in the list',
          );
          expect(before, contains('blur('));
          final drawn = await shoot(page);

          await emulate(page, media.value);
          await _settle(page);
          final after = await _read(page, _computedFilter('ps'));
          final plain = await shoot(page);
          await page.close();

          expect(after, isNot(contains('url(')), reason: after);
          // What is left is the list the glass always had.
          expect(after, contains('blur('));
          expect(after, contains('brightness('));

          // And it paints what a tuning that never stated them paints,
          // under the same preference.
          final reference = await open(unfinished);
          await emulate(reference, media.value);
          await _settle(reference);
          final expected = await shoot(reference);
          await reference.close();

          expect(
            diffRatio(plain, expected),
            lessThan(kUnchangedRatioCeiling),
            reason: '${media.key}: the surface still draws a term',
          );
          // The preference changed something: the terms did draw.
          expect(
            diffRatio(drawn, plain),
            greaterThan(kMovedRatioFloor),
            reason: 'the terms drew nothing to take away',
          );
        },
        skip: skipReason,
      );
    }

    test(
      'the terms return when the preference does',
      () async {
        final page = await open(finished);
        await emulate(page, {'prefers-contrast': 'more'});
        await _settle(page);
        expect(
          await _read(page, _computedFilter('ps')),
          isNot(contains('url(')),
        );

        await emulate(page, {'prefers-contrast': 'no-preference'});
        await _settle(page);
        expect(await _read(page, _computedFilter('ps')), contains('url('));
        await page.close();
      },
      skip: skipReason,
    );

    test(
      'reduced transparency takes the whole list away',
      () async {
        final page = await open(finished);
        await emulate(page, {'prefers-reduced-transparency': 'reduce'});
        await _settle(page);

        expect(await _read(page, _computedFilter('ps')), 'none');
        await page.close();
      },
      skip: skipReason,
    );

    test(
      'a policy that blocks data: images takes the terms away and keeps the '
      'rest of the list',
      () async {
        // The filter documents travel as data URLs. A site whose
        // Content-Security-Policy does not allow them loses the two terms —
        // that is the claim the guide makes, held here rather than asserted.
        const blocked =
            '<meta http-equiv="Content-Security-Policy" '
            'content="img-src \'none\'">';
        Future<img.Image> shotUnder(CoreSurfaceTuning tuning) async {
          final page = await open(tuning, headHtml: blocked);
          final shot = await shoot(page);
          await page.close();

          return shot;
        }

        final withTerms = await shotUnder(finished);
        final without = await shotUnder(unfinished);
        final open_ = await shotOf(finished);
        final ratio = diffRatio(withTerms, without);
        final drawn = diffRatio(open_, without);
        stdout.writeln(
          'J3-csp blocked-vs-without=${ratio.toStringAsFixed(4)} '
          'allowed-vs-without=${drawn.toStringAsFixed(4)}',
        );

        // The terms draw where the policy allows them (the premise) ...
        expect(drawn, greaterThan(kMovedRatioFloor));
        // ... and where it does not the surface draws what a tuning that
        // never stated them draws — blur, chroma lift and dimming intact.
        expect(ratio, lessThan(kUnchangedRatioCeiling));
      },
      skip: skipReason,
    );

    // ------------------------------------------------------------------
    // A browser that draws nothing for a list that names an SVG filter
    // ------------------------------------------------------------------

    // WebKit and Gecko accept the value and then draw nothing for a list that
    // names the frost or the shade — the blur included — so the host, which
    // every app root installs, writes an attribute on `<html>` and the sheet's
    // rule takes the two terms out. This is the whole path (user agent →
    // compiled host → attribute → rule → computed list → pixels) in Chromium
    // with the user agent overridden before the page loads; what WebKit then
    // draws with the list that is left is the browser's own and is measured
    // in Safari.
    for (final agent in {
      'Safari': _kSafariUserAgent,
      'Firefox': _kFirefoxUserAgent,
      'Chrome on iOS (WebKit)': _kChromeOnIosUserAgent,
    }.entries) {
      test(
        '${agent.key} loses the two terms and keeps the rest of the glass',
        () async {
          final page = await open(finished, userAgent: agent.value);
          final before = await _read(page, _computedFilter('ps'));
          expect(
            before,
            contains('url('),
            reason:
                'the premise: until the host is installed, the terms '
                'are in the list',
          );

          await install(page);
          expect(
            await _read(
              page,
              "document.documentElement.getAttribute('data-coui-svg-backdrop')",
            ),
            'off',
          );
          final after = await _read(page, _computedFilter('ps'));
          expect(after, isNot(contains('url(')), reason: after);
          // What is left is the list the glass always had.
          expect(after, contains('blur('));
          expect(after, contains('brightness('));
          final plain = await shoot(page);
          await page.close();

          // And it paints what a tuning that never stated them paints, in the
          // same browser with the same host installed.
          final reference = await open(unfinished, userAgent: agent.value);
          await install(reference);
          final expected = await shoot(reference);
          await reference.close();
          expect(
            diffRatio(plain, expected),
            lessThan(kUnchangedRatioCeiling),
            reason: '${agent.key}: the surface still draws a term',
          );
        },
        skip: skipReason,
      );
    }

    for (final agent in {
      'Chrome': _kChromeUserAgent,
      'Edge': _kEdgeUserAgent,
    }.entries) {
      test(
        '${agent.key} writes nothing and keeps the two terms',
        () async {
          final page = await open(finished, userAgent: agent.value);
          await install(page);

          expect(
            await _read(
              page,
              "document.documentElement.hasAttribute('data-coui-svg-backdrop')",
            ),
            'false',
          );
          expect(await _read(page, _computedFilter('ps')), contains('url('));

          // The first-paint route is in the page, and this browser does not
          // answer its query — which is why it keeps the terms with no
          // attribute and no script.
          expect(
            await _read(page, '$_firstPaintQueries.length'),
            '1',
            reason: 'the page carries no first-paint query to answer',
          );
          expect(
            await _read(
              page,
              'JSON.stringify($_firstPaintQueries'
              '.map((rule) => CSS.supports(rule.conditionText)))',
            ),
            '[false]',
          );
          await page.close();
        },
        skip: skipReason,
      );
    }

    // A browser that answers the query takes the terms out at the first style
    // resolution: no script has run, and no attribute is written. Chromium
    // never answers it, so the page's own text has the query made true — what
    // is tested is the rule it guards, in a real cascade, against the
    // palette's own `--coui-surface-frost` / `--coui-surface-shade`.
    test(
      'the first-paint route takes the two terms out before any script runs',
      () async {
        String makeQueryTrue(String html) {
          final out = html.replaceFirst(
            RegExp(r'@supports \(-apple-pay-button-style:black\)[^{]*\{'),
            '@supports (display:block){',
          );
          expect(out, isNot(html), reason: 'the page has no query to answer');

          return out;
        }

        final page = await open(
          finished,
          userAgent: _kChromeUserAgent,
          transform: makeQueryTrue,
        );
        // No host: nothing has told the page which browser this is.
        expect(
          await _read(
            page,
            "document.documentElement.hasAttribute('data-coui-svg-backdrop')",
          ),
          'false',
        );
        final list = await _read(page, _computedFilter('ps'));
        expect(list, isNot(contains('url(')), reason: list);
        expect(list, contains('blur('));
        expect(list, contains('brightness('));
        final plain = await shoot(page);
        await page.close();

        final reference = await open(unfinished, userAgent: _kChromeUserAgent);
        final expected = await shoot(reference);
        await reference.close();
        expect(
          diffRatio(plain, expected),
          lessThan(kUnchangedRatioCeiling),
          reason: 'the surface still draws a term',
        );
      },
      skip: skipReason,
    );

    // ------------------------------------------------------------------
    // Nothing leaks, and a nested surface draws none
    // ------------------------------------------------------------------

    test(
      'an untuned page carries no filter document at all',
      () async {
        final page = await open(CoreSurfaceTuning.none);
        final list = await _read(page, _computedFilter('ps'));
        stdout.writeln('J3-untuned $list');

        expect(list, isNot(contains('url(')));
        expect(
          await _read(
            page,
            'getComputedStyle(document.documentElement)'
            ".getPropertyValue('$kWebSurfaceFrostVar-liquidGlass-light')",
          ),
          isEmpty,
        );
        await page.close();
      },
      skip: skipReason,
    );

    test(
      'a surface nested in a surface draws no pass, so no frost and no shade',
      () async {
        final page = await open(finished);
        final outer = await _read(page, _computedFilter('pf'));
        final nested = await _read(page, _computedFilter('nested'));
        stdout.writeln('J3-nested outer=${outer.length}ch nested=$nested');

        expect(outer, contains('url('));
        expect(nested, isNot(contains('url(')));
        await page.close();
      },
      skip: skipReason,
    );

    // ------------------------------------------------------------------
    // The document-level runtime
    // ------------------------------------------------------------------

    test(
      'the host still bends a surface whose list carries the stylesheet '
      'filters, and follows the preference when it flips',
      () async {
        final page = await open(finished);
        await install(page);

        final bent = await _holds(
          page,
          "${_inlineFilter('ps')}.indexOf('coui-refraction') >= 0",
        );
        final inline = await _read(page, _inlineFilter('ps'));
        stdout.writeln('J3-host bent=$bent inline=${inline.length}ch');

        expect(bent, isTrue, reason: 'the host saw `url(` and never bent');
        expect(
          inline,
          contains('data:image/svg'),
          reason: 'and the stylesheet terms are still in the copied list',
        );

        await emulate(page, {'prefers-contrast': 'more'});
        final plain = await _holds(
          page,
          "${_inlineFilter('ps')}.indexOf('data:image/svg') < 0",
        );
        expect(
          plain,
          isTrue,
          reason:
              'the runtime kept the list it copied under the old preference: '
              '${await _read(page, _inlineFilter('ps'))}',
        );

        await emulate(page, {'prefers-contrast': 'no-preference'});
        final restored = await _holds(
          page,
          "${_inlineFilter('ps')}.indexOf('data:image/svg') >= 0",
        );
        expect(restored, isTrue);
        await page.close();
      },
      skip: skipReason,
    );

    // ------------------------------------------------------------------
    // The rim terms that were not built
    // ------------------------------------------------------------------

    test(
      'a ring beside the glass keys a term on luminance; one inside it cannot',
      () async {
        final page = await browser.newPage();
        final file = File(p.join(buildDir.path, 'ring-${pageCount++}.html'))
          ..writeAsStringSync(_ringHtml());
        await page.goto(Uri.file(file.path).toString(), wait: Until.load);
        await _settle(page);
        final shot = await shoot(page);
        await page.close();

        // The ring turns luminance upside down at half contrast about
        // mid-grey: a backdrop of luminance L reads 0.5 + 0.5 (0.5 − L).
        int turned(int backdrop) =>
            ((0.5 + 0.5 * (0.5 - backdrop / 255)) * 255).round();

        var worstBeside = 0;
        var worstInside = 0;
        var worstInterior = 0;
        for (var i = 0; i < _kRingGreys.length; i++) {
          final x = _kRingXs[i];
          // One pixel in from the left edge, half way down: on the ring.
          final backdrop = _at(shot, x + 1, _kRingControlTop + 30).r;
          final beside = _at(shot, x + 1, _kRingBesideTop + 30).r;
          final inside = _at(shot, x + 1, _kRingInsideTop + 30).r;
          final interior = _at(shot, x + 30, _kRingBesideTop + 30).r;
          final control = _at(shot, x + 30, _kRingControlTop + 30).r;
          final offBeside = (beside - turned(backdrop)).abs();
          final offInside = (inside - backdrop).abs();
          final offInterior = (interior - control).abs();
          if (offBeside > worstBeside) worstBeside = offBeside;
          if (offInside > worstInside) worstInside = offInside;
          if (offInterior > worstInterior) worstInterior = offInterior;
          expect(
            offBeside,
            lessThanOrEqualTo(_kTolerance),
            reason:
                'grey ${_kRingGreys[i]}: backdrop=$backdrop ring=$beside '
                'want=${turned(backdrop)}',
          );
          expect(
            offInside,
            lessThanOrEqualTo(_kTolerance),
            reason:
                'grey ${_kRingGreys[i]}: a ring inside the glass saw the '
                'page — backdrop=$backdrop ring=$inside',
          );
          expect(
            offInterior,
            lessThanOrEqualTo(_kTolerance),
            reason: 'grey ${_kRingGreys[i]}: the ring reached the interior',
          );
        }
        stdout.writeln(
          'J3-ring beside-vs-want worst=$worstBeside '
          'inside-vs-backdrop worst=$worstInside '
          'interior worst=$worstInterior',
        );

        // The direction: light over dark, shade over bright.
        final overBlack = _at(shot, _kRingXs.first + 1, _kRingBesideTop + 30).r;
        final overWhite = _at(shot, _kRingXs.last + 1, _kRingBesideTop + 30).r;
        expect(overBlack, greaterThan(150));
        expect(overWhite, lessThan(100));

        // Smooth, not stepped: along a ramp the ring follows the backdrop
        // pixel by pixel.
        var worstRamp = 0;
        for (final dx in [20, 80, 140, 200, 260, 320, 360]) {
          final x = 10 + dx;
          final backdrop = _at(shot, x, 250 + 20).r;
          final ring = _at(shot, x, 250 + 1).r;
          final off = (ring - turned(backdrop)).abs();
          if (off > worstRamp) worstRamp = off;
          expect(
            off,
            lessThanOrEqualTo(_kTolerance),
            reason: 'ramp x=$x: backdrop=$backdrop ring=$ring',
          );
        }
        stdout.writeln('J3-ring ramp worst=$worstRamp');
      },
      skip: skipReason,
    );

    // ------------------------------------------------------------------
    // The preset
    // ------------------------------------------------------------------

    for (final theme in ['light', 'dark']) {
      test(
        'the iOS 27 preset draws both terms in a $theme page',
        () async {
          final page = await open(CoreSurfaceTuning.ios27, theme: theme);
          // The preset as an app sees it: with its fill.
          await page.evaluate<void>(
            "() => document.querySelectorAll('[data-clear]').forEach(function "
            "(e) { e.style.backgroundColor = ''; })",
          );
          await _settle(page);
          final withFinish = await shoot(page);

          // The same page with the two terms blanked and nothing else: the
          // rule the stylesheet applies under more contrast, without the
          // preference.
          await page.addStyleTag(
            content:
                ':where(.coui-surface){$kWebSurfaceFrostVar:initial !important;'
                '$kWebSurfaceShadeVar:initial !important;}',
          );
          await _settle(page);
          final without = await shoot(page);
          await page.close();

          final moved = diffRatio(withFinish, without);
          stdout.writeln('J3-preset $theme moved=${moved.toStringAsFixed(4)}');
          expect(moved, greaterThan(kMovedRatioFloor));

          final dir = Platform.environment['J3_SHOTS_DIR'];
          if (dir != null) {
            Directory(dir).createSync(recursive: true);
            File(
              p.join(dir, 'preset-$theme-with.png'),
            ).writeAsBytesSync(img.encodePng(withFinish));
            File(
              p.join(dir, 'preset-$theme-without.png'),
            ).writeAsBytesSync(img.encodePng(without));
          }
        },
        skip: skipReason,
      );
    }
  });
}

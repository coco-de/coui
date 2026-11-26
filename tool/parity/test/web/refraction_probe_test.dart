// M2 of the Tier 2 refraction feasibility measurement — the Web half.
//
// Answers, in Chromium, by pixels only:
//
//   P1  Does an SVG displacement map ridden through `backdrop-filter` move
//       the pixels behind a surface?
//   P2  On a page reproducing static-render order, is the Tier 1 glass already
//       drawn in the frame before the refraction script runs?
//   P3  Safari / Firefox fallback — NOT measured. See the note at the bottom.
//
// ## Why nothing here asks the browser whether it can
//
// `CSS.supports('backdrop-filter', 'url(#f)')` returns true in Safari and
// Firefox, which parse the value and then render nothing. A probe that
// believed it would report a capability that does not exist. So every verdict
// below is a comparison of captured pixels, and the support query appears
// nowhere.
//
// ## What keeps a pass from being vacuous
//
// Three controls, each disproving a different way the measurement could be
// accidentally true:
//
//   bare blur      — if this build of Chromium composites no `backdrop-filter`
//                    at all, every later result would be a statement about the
//                    harness wearing the costume of a finding.
//   dangling ref   — a reference to a filter id that does not exist must
//                    change nothing, or "it changed" means only "we drew".
//   neutral map    — `feDisplacementMap` reads a channel and subtracts a half.
//                    A map with no neutral value displaces *everything*, so a
//                    map of zeroes would "differ" while measuring nothing. The
//                    generator writes 128 where it means no displacement, and
//                    this control is what proves it.
//
// ## The one thing that has to be right for any of it to mean anything
//
// The filter reference is APPENDED to the surface's own `backdrop-filter`,
// never substituted for it, and every capture carries the identical chain — so
// the only thing that differs between two captures is the image the map reads.
// Substituting instead of appending takes the Tier 1 blur away with it, and
// the difference that follows is mostly the blur leaving. That measures ~0.99
// of the panel and contains no displacement at all, which is worse than a
// failure: it is a large, confident, wrong number.
//
// A run with no Chrome on the machine is skipped, not zeroed — `skip:` reports
// it as not run, which is the distinction the measurement depends on.
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/panel_pixels.dart';

/// Mirrors `computed_style_probe_test.dart`'s system-Chrome lookup.
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

const kViewportWidth = 400;
const kViewportHeight = 300;

/// Panel geometry, shared by the page and the capture clip.
const kPanelLeft = 100;
const kPanelTop = 75;
const kPanelWidth = 200;
const kPanelHeight = 150;

/// Corner radius and the width of the band the refraction is concentrated in.
const kPanelRadius = 24;
const kBandWidth = 18;

/// `feDisplacementMap` scale, in user units. Large enough that a displacement
/// is unmistakable at this panel size.
const kDisplacementScale = 40;

/// Signed-distance generator for a rounded rect, writing the edge normal into
/// R and G with 128 as "do not displace".
///
/// The squaring of `t` concentrates the displacement into the outer band and
/// leaves the interior optically flat, which is what makes the result read as
/// a lens rather than a smear.
const String _kSdfJs = '''
function couiMakeSdf(w, h, radius, band) {
  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d');
  const image = ctx.createImageData(w, h);
  const data = image.data;
  const halfW = w / 2, halfH = h / 2;
  const r = Math.min(radius, Math.min(halfW, halfH));
  function signedDistance(x, y) {
    const qx = Math.abs(x - halfW) - (halfW - r);
    const qy = Math.abs(y - halfH) - (halfH - r);
    const mx = Math.max(qx, 0), my = Math.max(qy, 0);
    return Math.sqrt(mx * mx + my * my) + Math.min(Math.max(qx, qy), 0) - r;
  }
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const px = x + 0.5, py = y + 0.5;
      const gx = signedDistance(px + 1, py) - signedDistance(px - 1, py);
      const gy = signedDistance(px, py + 1) - signedDistance(px, py - 1);
      const len = Math.hypot(gx, gy) || 1;
      const inset = -signedDistance(px, py);
      const t = inset <= 0 ? 1 : Math.max(0, 1 - inset / band);
      const k = t * t;
      const i = (y * w + x) * 4;
      data[i] = Math.round(((gx / len) * k * 0.5 + 0.5) * 255);
      data[i + 1] = Math.round(((gy / len) * k * 0.5 + 0.5) * 255);
      data[i + 2] = 0;
      data[i + 3] = 255;
    }
  }
  ctx.putImageData(image, 0, 0);
  return canvas.toDataURL('image/png');
}
function couiMakeNeutral(w, h) {
  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = 'rgb(128,128,0)';
  ctx.fillRect(0, 0, w, h);
  return canvas.toDataURL('image/png');
}
''';

/// The page body.
///
/// The backdrop is hard-edged on purpose. A blur of a smooth gradient is very
/// nearly the gradient again, and P2 would then have nothing to see; a blur of
/// a sharp stripe is a wide ramp of intermediates that is trivially decidable.
///
/// `--coui-surface-rgb` is written inline because it is deliberately absent
/// from the stylesheet — every component publishes it from whichever token it
/// chose. Omitting it here would leave `background-color` invalid, the panel
/// would render transparent, and P2 would fail for a reason that has nothing
/// to do with render order.
///
/// `coui-surface-functional`, not `-content` — the role liquidGlass actually
/// blurs under (#4424); content draws flat under this style.
String _bodyHtml() =>
    '''
<style>
  body { margin: 0; width: ${kViewportWidth}px; height: ${kViewportHeight}px; }
  #bg { position: absolute; inset: 0;
        background: repeating-linear-gradient(90deg,
          #000 0 12px, #fff 12px 24px); }
  .panel { position: absolute; top: ${kPanelTop}px;
           width: ${kPanelWidth}px; height: ${kPanelHeight}px;
           border-radius: ${kPanelRadius}px; }
  #glass { left: ${kPanelLeft}px; }
  #control { left: ${kPanelLeft}px; }
  #bare { left: ${kPanelLeft}px; backdrop-filter: blur(16px);
          -webkit-backdrop-filter: blur(16px); }
  .hidden { display: none; }
</style>
<div id="bg"></div>
<div id="control" class="panel hidden"></div>
<div id="bare" class="panel hidden"></div>
<div id="glass" class="panel coui-surface coui-surface-functional"
     style="--coui-surface-rgb: var(--coui-surface);"></div>
<svg width="0" height="0" style="position:absolute" aria-hidden="true">
  <filter id="refract" x="0%" y="0%" width="100%" height="100%"
          filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB">
    <feImage id="map" preserveAspectRatio="none" result="map"/>
    <feDisplacementMap in="SourceGraphic" in2="map"
                       scale="$kDisplacementScale"
                       xChannelSelector="R" yChannelSelector="G"/>
  </filter>
</svg>
<script>
$_kSdfJs
window.__refractionRan = false;
window.__baseFilter = null;
// Gated rather than self-starting. Without a gate there is no frame anyone
// can name "before the script ran", and P2 would be measuring scheduler luck.
//
// The refraction is APPENDED to whatever the stylesheet already put on the
// surface, never substituted for it. Replacing it removes the Tier 1 blur, and
// the resulting difference is then mostly "the blur left" — a number that
// looks like a displacement and is not one. Reading the base off the computed
// style keeps it sourced from `theme_config.dart` rather than copied here.
window.__applyRefraction = function (filterRef) {
  const glass = document.getElementById('glass');
  if (window.__baseFilter === null) {
    window.__baseFilter = getComputedStyle(glass).backdropFilter;
  }
  const next = window.__baseFilter + ' ' + filterRef;
  glass.style.backdropFilter = next;
  glass.style.webkitBackdropFilter = next;
  window.__refractionRan = true;
};
window.__setMap = function (mapKind) {
  const uri = mapKind === 'neutral'
    ? couiMakeNeutral($kPanelWidth, $kPanelHeight)
    : couiMakeSdf($kPanelWidth, $kPanelHeight, $kPanelRadius, $kBandWidth);
  const fe = document.getElementById('map');
  fe.setAttribute('href', uri);
  fe.setAttributeNS('http://www.w3.org/1999/xlink', 'xlink:href', uri);
};
window.__showOnly = function (id) {
  for (const each of ['glass', 'control', 'bare']) {
    document.getElementById(each).classList.toggle('hidden', each !== id);
  }
};
</script>
''';

Future<void> _settle(Page page) async {
  // Two frames, not one: the first lets style changes land, the second lets
  // the compositor draw them. One frame reads back a stale surface often
  // enough to make a run flaky rather than wrong, which is worse.
  await page.evaluate<void>(
    '() => new Promise(function (done) { requestAnimationFrame(function () '
    '{ requestAnimationFrame(done); }); })',
  );
}

Future<img.Image> _shootPanel(Page page) async {
  final bytes = await page.screenshot(
    clip: const Rectangle(kPanelLeft, kPanelTop, kPanelWidth, kPanelHeight),
  );

  return img.decodePng(bytes)!;
}

void main() {
  final chromePath = _systemChromePath();
  final skipReason = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

  group('M2 — refraction in Chromium, judged by pixels', () {
    late Browser browser;
    late Page page;
    late Directory tempDir;

    setUpAll(() async {
      if (chromePath == null) return;
      browser = await launchCaptureBrowser(
        width: kViewportWidth,
        height: kViewportHeight,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      if (chromePath == null) return;
      await browser.close();
    });

    setUp(() async {
      if (chromePath == null) return;
      page = await browser.newPage();
      tempDir = Directory.systemTemp.createTempSync('refraction-probe-');

      // The page is assembled by the shipped harness rather than hand-written.
      // A literal copy of the glass CSS would be a second source that drifts
      // from `theme_config.dart`, and the measurement would then be about the
      // copy. The harness also reproduces the site's head order, including the
      // JS injection of the surface-style blocks — a static `<style>` was
      // measured to make style variants render byte-identically.
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: _bodyHtml(),
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        surfaceStyleId: 'liquidGlass',
      );
      final file = File(p.join(tempDir.path, 'refraction.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: Until.load);
      await _settle(page);
    });

    tearDown(() async {
      if (chromePath == null) return;
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    test(
      'control — this browser composites backdrop-filter at all',
      () async {
        await page.evaluate<void>("() => window.__showOnly('control')");
        await _settle(page);
        final plain = await _shootPanel(page);

        await page.evaluate<void>("() => window.__showOnly('bare')");
        await _settle(page);
        final blurred = await _shootPanel(page);

        // Everything below is a statement about refraction only if this holds.
        // If it fails, the right report is "the harness cannot render
        // backdrop-filter", not a verdict about the feature.
        expect(
          diffRatio(plain, blurred),
          greaterThan(kMovedRatioFloor),
          reason: 'headless Chromium composited no backdrop-filter',
        );
      },
      skip: skipReason,
    );

    test(
      'P1 — swapping only the map displaces the backdrop',
      () async {
        // Both captures carry the identical filter chain, and the only thing
        // that changes between them is the image the displacement map reads.
        // That is what makes the difference attributable to displacement
        // rather than to the surface gaining or losing a blur.
        await page.evaluate<void>("() => window.__setMap('neutral')");
        await page.evaluate<void>(
          "() => window.__applyRefraction('url(#refract)')",
        );
        await _settle(page);
        final neutral = await _shootPanel(page);

        // Appending a filter reference to a chain of shorthand functions is
        // not obviously legal, and an invalid chain drops silently — which
        // would leave both captures unfiltered and equal, reading as "no
        // displacement". The blur has to still be there for the comparison
        // below to be about anything.
        expect(
          luminanceBuckets(neutral),
          greaterThan(kBlurBucketFloor),
          reason: 'appending url() invalidated the whole filter chain',
        );

        await page.evaluate<void>("() => window.__setMap('sdf')");
        await _settle(page);
        final displaced = await _shootPanel(page);

        final moved = diffRatio(neutral, displaced);
        stdout.writeln(
          'M2-P1  movedRatio=${moved.toStringAsFixed(4)}'
          '  neutralBuckets=${luminanceBuckets(neutral)}',
        );

        expect(moved, greaterThan(kMovedRatioFloor));
      },
      skip: skipReason,
    );

    test(
      'P1-neutral — re-reading the same map changes nothing',
      () async {
        await page.evaluate<void>("() => window.__setMap('neutral')");
        await page.evaluate<void>(
          "() => window.__applyRefraction('url(#refract)')",
        );
        await _settle(page);
        final first = await _shootPanel(page);

        await page.evaluate<void>("() => window.__setMap('neutral')");
        await _settle(page);
        final second = await _shootPanel(page);

        // The floor under P1. If re-applying an identical map produced a
        // difference, the ratio P1 reports would be capture noise and the
        // measurement would be unfalsifiable. It also pins the neutral value:
        // `feDisplacementMap` subtracts a half from the normalised channel, so
        // a map of zeroes would shove every pixel by half the scale — 128 is
        // the value that means stay, and a wrong one would show up here.
        final noise = diffRatio(first, second);
        stdout.writeln('M2-P1-neutral  ratio=${noise.toStringAsFixed(4)}');

        expect(noise, lessThan(kUnchangedRatioCeiling));
      },
      skip: skipReason,
    );

    test(
      'P1-dangling — a reference to no filter displaces nothing',
      () async {
        await page.evaluate<void>("() => window.__setMap('neutral')");
        await page.evaluate<void>(
          "() => window.__applyRefraction('url(#refract)')",
        );
        await _settle(page);
        final neutral = await _shootPanel(page);

        // The map stays the displacing one; only the reference goes nowhere.
        // So anything that survives here cannot be the map's doing.
        await page.evaluate<void>("() => window.__setMap('sdf')");
        await page.evaluate<void>(
          "() => window.__applyRefraction('url(#does-not-exist)')",
        );
        await _settle(page);
        final dangling = await _shootPanel(page);

        final inlineValue = await page.evaluate<String>(
          "() => document.getElementById('glass').style.backdropFilter",
        );
        stdout.writeln(
          'M2-P1-dangling  ratio='
          '${diffRatio(neutral, dangling).toStringAsFixed(4)}'
          '  inline="$inlineValue"',
        );

        // Note for anyone reusing this: the reference has to be APPENDED to
        // the surface's own filter, never substituted for it. Substituting
        // removes the Tier 1 blur, and the difference that follows is mostly
        // the blur leaving — a number large enough to look like a strong
        // displacement while containing none.
        expect(
          diffRatio(neutral, dangling),
          lessThan(kUnchangedRatioCeiling),
          reason: 'a filter that does not exist moved the backdrop',
        );
      },
      skip: skipReason,
    );

    test(
      'P2 — the Tier 1 glass is drawn before the refraction script runs',
      () async {
        final ranBefore = await page.evaluate<bool>(
          '() => window.__refractionRan',
        );
        expect(
          ranBefore,
          isFalse,
          reason: 'nothing may have triggered the runtime yet',
        );

        final glass = await _shootPanel(page);

        await page.evaluate<void>("() => window.__showOnly('control')");
        await _settle(page);
        final bare = await _shootPanel(page);

        // Not transparent: the surface painted something over the backdrop.
        expect(
          diffRatio(bare, glass),
          greaterThan(kMovedRatioFloor),
          reason: 'the surface drew nothing before the script ran',
        );

        stdout.writeln(
          'M2-P2  refractionRan=$ranBefore'
          '  glassVsBare=${diffRatio(bare, glass).toStringAsFixed(4)}'
          '  glassBuckets=${luminanceBuckets(glass)}'
          '  bareBuckets=${luminanceBuckets(bare)}',
        );

        // Not merely tinted: a fill alone would shift the histogram without
        // spreading it. The blur is what turns two stripe values into a ramp,
        // so the bucket count is what separates "glass" from "coloured box".
        expect(
          luminanceBuckets(glass),
          greaterThan(kBlurBucketFloor),
          reason: 'the surface has a fill but no backdrop blur',
        );
      },
      skip: skipReason,
    );
  });

  // P3 — Safari and Firefox are not measured, and no result is recorded for
  // them. This repo drives exactly one browser: puppeteer against Chromium.
  // There is no Safari or Firefox driver, no WebDriver, no Playwright and no
  // Selenium anywhere in it. Writing a test that reported anything about those
  // engines would be reporting a harness that does not exist, and shrinking
  // the claim until it passed would be worse than leaving the axis open.
}

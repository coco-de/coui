// The formal judgement on Web refraction — promoted from the feasibility
// measurement in `refraction_probe_test.dart`.
//
// The difference between the two is what is under the microscope. The
// feasibility probe answered "can Chromium do this at all" and generated its
// displacement map with page JS written for that question. This one drives the
// **shipped** runtime — `refraction_map_web.dart`, compiled into the page — so
// a regression in the code users get is a failure here.
//
// That distinction is the whole point of promoting it. A probe carrying its
// own copy of the map generator keeps passing after the runtime it stands for
// has drifted away from it, and it does so while looking like coverage.
//
// ## The judgement is pixels, never a support query
//
// `CSS.supports('backdrop-filter', 'url(#f)')` returns true in Safari and
// Firefox, which parse the value and then render nothing. Every verdict below
// is a comparison of captured pixels and no capability question appears
// anywhere.
//
// ## What isolates displacement from everything else
//
// Two panels of identical geometry, both attached by the shipped runtime,
// differing in exactly one input: `bezel`. Bezel reaches the screen only
// through the generated map, so a difference between those two captures cannot
// be the surface gaining or losing a blur — the thing that made the naive
// version of this measurement read ~0.99 while containing no displacement.
//
// Three controls keep a pass from being vacuous:
//
//   same bezel   — two panels given the same bezel must capture identically,
//                  or the ratio the judgement reports is capture noise and
//                  nothing here is falsifiable.
//   interior     — the flat middle of the panel must not move, which is what
//                  pins the map's neutral value in the shipped generator.
//   is it glass  — the panel under judgement must occupy many luminance
//                  buckets, i.e. it is actually a blurred surface and not an
//                  unstyled div the harness failed to style. Without this the
//                  whole file could be a confident measurement of a plain box.
//
// Each was injected with the regression it names and observed to fail. Two
// things that look like controls are deliberately *not* claimed as such,
// because injecting their regressions showed they do not catch them:
//
//   * a substitution instead of an append leaves the bucket count at 20 — the
//     translucent fill and the displacement still spread luminance without any
//     blur — while `movedRatio` stays at 0.198, comfortably over the floor.
//     What catches it is the interior control and the explicit read-back.
//   * an invalid filter chain leaves the bucket count at 24, because Chromium
//     drops the invalid inline value and the element falls back to the
//     stylesheet's blur rather than to nothing. What catches it is the ratio
//     going to zero, and the read-back finding an empty inline value.
//
// A run with no Chrome on the machine is skipped, not zeroed.
import 'dart:convert';
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

const _kViewportWidth = 400;
const _kViewportHeight = 300;

/// Panel geometry, shared by the page and the capture clip.
const _kPanelLeft = 100;
const _kPanelTop = 75;
const _kPanelWidth = 200;
const _kPanelHeight = 150;
const _kPanelRadius = 24;

/// Two bezels far enough apart that the maps they generate cannot be confused.
const _kWideBezel = 0.45;
const _kNarrowBezel = 0.05;

/// The entry point compiled into the page. Its exports are the only way this
/// probe reaches the runtime, which is what keeps it honest about testing the
/// shipped code rather than a re-statement of it.
const _kEntryPath = 'tool/parity/src/web/refraction_runtime_entry.dart';

/// The table `coui_core` pins `surfaceRefractionBrowserSupported` with: a user
/// agent, and whether that browser draws an SVG filter named in
/// `backdrop-filter`.
const _kBrowserVectorsPath =
    'packages/coui_core/test/fixtures/refraction_browser_vectors.json';

List<Map<String, Object?>> _browserCases() =>
    ((jsonDecode(File(_kBrowserVectorsPath).readAsStringSync())
                as Map<String, Object?>)['cases']!
            as List<Object?>)
        .cast<Map<String, Object?>>();

/// Four identical surfaces, shown one at a time.
///
/// Identical because the judgement compares captures of the same clip
/// rectangle — anything differing besides the bezel would land in the ratio and
/// be read as displacement.
///
/// Shown one at a time because the runtime measures the element it is given,
/// and a hidden element measures zero. Each is displayed before it is attached,
/// which is also the order a real mount takes.
///
/// The backdrop is hard-edged on purpose: a blur of a smooth gradient is very
/// nearly the gradient again, so the luminance-bucket control would have
/// nothing to see. `--coui-surface-rgb` is written inline because it is
/// deliberately absent from the stylesheet — every component publishes it from
/// whichever token it chose, and without it `background-color` is invalid and
/// the panel renders transparent.
///
/// `coui-surface-functional`, not `-content` — this is the role liquidGlass
/// actually blurs under (#4424). The content role draws flat under this
/// style, so a panel marked content would have no base filter to append
/// to at all.
String _bodyHtml() =>
    '''
<style>
  body { margin: 0; width: ${_kViewportWidth}px; height: ${_kViewportHeight}px; }
  #bg { position: absolute; inset: 0;
        background: repeating-linear-gradient(90deg,
          #000 0 12px, #fff 12px 24px); }
  .panel { position: absolute; top: ${_kPanelTop}px; left: ${_kPanelLeft}px;
           width: ${_kPanelWidth}px; height: ${_kPanelHeight}px;
           border-radius: ${_kPanelRadius}px; }
  .hidden { display: none; }
</style>
<div id="bg"></div>
<div id="wide" class="panel coui-surface coui-surface-functional hidden"
     style="--coui-surface-rgb: var(--coui-surface);"></div>
<div id="narrow" class="panel coui-surface coui-surface-functional hidden"
     style="--coui-surface-rgb: var(--coui-surface);"></div>
<div id="twin" class="panel coui-surface coui-surface-functional hidden"
     style="--coui-surface-rgb: var(--coui-surface);"></div>
<div id="resized" class="panel coui-surface coui-surface-functional hidden"
     style="--coui-surface-rgb: var(--coui-surface);"></div>
<div id="plain" class="panel coui-surface coui-surface-functional hidden"
     style="--coui-surface-rgb: var(--coui-surface);"></div>
<script>
window.__showOnly = function (id) {
  for (const each of ['wide', 'narrow', 'twin', 'resized', 'plain']) {
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
    clip: const Rectangle(_kPanelLeft, _kPanelTop, _kPanelWidth, _kPanelHeight),
  );

  return img.decodePng(bytes)!;
}

/// The part of the panel a narrow bezel is supposed to leave alone.
///
/// Inset well past the narrow band (`min(w, h) * bezel`), so everything inside
/// it is interior by the generator's own definition.
const _kInteriorInset = 24;

Future<img.Image> _shootInterior(Page page) async {
  final bytes = await page.screenshot(
    clip: const Rectangle(
      _kPanelLeft + _kInteriorInset,
      _kPanelTop + _kInteriorInset,
      _kPanelWidth - (_kInteriorInset * 2),
      _kPanelHeight - (_kInteriorInset * 2),
    ),
  );

  return img.decodePng(bytes)!;
}

/// Shows a panel, hands it to the shipped runtime, and captures it.
Future<img.Image> _attachAndShoot(
  Page page,
  String id, {
  required double bezel,
}) async {
  await page.evaluate<void>("() => window.__showOnly('$id')");
  await _settle(page);
  await page.evaluate<void>(
    "() => { window.__detach_$id = window.couiAttachRefraction('$id', $bezel); }",
  );
  await _settle(page);

  return _shootPanel(page);
}

void main() {
  final chromePath = _systemChromePath();
  final skipReason = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

  group('the shipped Web runtime, judged by pixels', () {
    late Browser browser;
    late Page page;
    late Directory tempDir;
    late String compiledJs;

    setUpAll(() async {
      if (chromePath == null) return;

      // Compiled once. The entry lives in the repo rather than being written
      // here so that package resolution is the workspace's own — a copy
      // assembled at run time would resolve against nothing.
      final buildDir = Directory.systemTemp.createTempSync('refraction-build-');
      final output = p.join(buildDir.path, 'runtime.js');
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
        reason: 'compiling the shipped runtime failed:\n${result.stderr}',
      );
      compiledJs = File(output).readAsStringSync();
      buildDir.deleteSync(recursive: true);

      browser = await launchCaptureBrowser(
        width: _kViewportWidth,
        height: _kViewportHeight,
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
      tempDir = Directory.systemTemp.createTempSync('refraction-runtime-');

      // Assembled by the shipped harness rather than hand-written, so the
      // surface's own `backdrop-filter` comes from `theme_config.dart`. That
      // matters more here than in the feasibility probe: the runtime reads
      // that value off the computed style and appends to it, so a hand-copied
      // stylesheet would make the append rule a statement about the copy.
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '${_bodyHtml()}<script>$compiledJs</script>',
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        surfaceStyleId: 'liquidGlass',
      );
      final file = File(p.join(tempDir.path, 'runtime.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: Until.load);
      await _settle(page);
      await page.evaluate<void>('() => window.couiResetRefractionCache()');
    });

    tearDown(() async {
      if (chromePath == null) return;
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    test(
      'control — two surfaces given the same bezel capture identically',
      () async {
        // The floor under the judgement. If this failed, the ratio reported
        // below would be capture noise and the measurement unfalsifiable.
        final first = await _attachAndShoot(page, 'wide', bezel: _kWideBezel);
        final second = await _attachAndShoot(page, 'twin', bezel: _kWideBezel);

        final noise = diffRatio(first, second);
        stdout.writeln('W3-same-bezel  ratio=${noise.toStringAsFixed(4)}');

        expect(noise, lessThan(kUnchangedRatioCeiling));
      },
      skip: skipReason,
    );

    test(
      'the bezel is the only input, and it moves the backdrop',
      () async {
        final wide = await _attachAndShoot(page, 'wide', bezel: _kWideBezel);

        // Is the thing under judgement glass at all? A striped backdrop seen
        // flat lands in two luminance buckets; seen through a blur it lands in
        // a couple of dozen. If the harness failed to apply the surface style,
        // every ratio in this file would be a confident measurement of a plain
        // box, and nothing else here would say so.
        //
        // This does *not* detect a substituted filter or an invalid chain —
        // both were injected and left the count above the floor. See the note
        // at the top of the file for what catches those.
        expect(
          luminanceBuckets(wide),
          greaterThan(kBlurBucketFloor),
          reason: 'the panel under judgement is not a blurred surface',
        );

        final narrow = await _attachAndShoot(
          page,
          'narrow',
          bezel: _kNarrowBezel,
        );

        final moved = diffRatio(wide, narrow);
        stdout.writeln(
          'W3-bezel  movedRatio=${moved.toStringAsFixed(4)}'
          '  wideBuckets=${luminanceBuckets(wide)}',
        );

        expect(moved, greaterThan(kMovedRatioFloor));
      },
      skip: skipReason,
    );

    // 이 패널의 `blur(4px)` 아래에서 배경 스트라이프는 선명하게 남고, 맵이
    // "움직이지 마라"를 8비트로 적은 128(표현 불가능한 127.5 가 아니라)이
    // `feDisplacementMap` 에서 `128/255 - 0.5 ≈ 0.00196` 으로 읽혀 0.098px
    // 서브픽셀 잔차를 남긴다. 8비트 채널에서 지울 수 없는 값이다.
    //
    // 그 잔차가 어느 픽셀을 반올림 경계 너머로 미느냐는 화면이 아니라
    // 래스터/캡처 경로가 정한다 — 같은 커밋·같은 Chrome 에서 브라우저가
    // 여럿 경합하면 같은 장면이 1095 · 3455 · 5035 픽셀로 세어졌고 세
    // 상태 모두 채널당 최대 차이가 정확히 1 이었다(#4672). 그래서 이
    // 천장은 한때 그 요동 위에 얹혀 0.12 였다.
    //
    // 지금은 `diffRatio` 가 1 LSB 를 노이즈 바닥으로 보고 세지 않으므로
    // (`kChannelNoiseFloor`) 그 요동이 통째로 사라진다 — 세 상태가 전부
    // 0.0000 이 되고, 이 장면에 주입한 진짜 회귀(중성 맵에 128 대신 0)는
    // 0.9342 로 남는다. 천장이 요동 위가 아니라 0 바로 위에 설 수 있게 되어
    // 공용 상수를 그대로 쓴다 — 이 테스트는 그만큼 강해졌다.

    test(
      'the interior of the panel is left where it was',
      () async {
        // This is what pins the map's neutral value to 128 in the **shipped**
        // generator. `feDisplacementMap` subtracts a half from the normalised
        // channel, so a generator writing 0 where it means "do not move"
        // shoves every pixel by half the scale — the flat interior included.
        //
        // Nothing else here would notice. Two bezels would still differ, two
        // equal bezels would still match, and the whole panel would be sliding.
        // The feasibility probe does check the neutral, but against its own
        // page-JS copy of the generator, so it cannot speak for this one.
        await page.evaluate<void>("() => window.__showOnly('plain')");
        await _settle(page);
        final unrefracted = await _shootInterior(page);

        await page.evaluate<void>("() => window.__showOnly('narrow')");
        await _settle(page);
        await page.evaluate<void>(
          '() => { window.__detach_narrow = '
          "window.couiAttachRefraction('narrow', $_kNarrowBezel); }",
        );
        await _settle(page);
        final refracted = await _shootInterior(page);

        final moved = diffRatio(unrefracted, refracted);
        stdout.writeln('W3-interior  ratio=${moved.toStringAsFixed(4)}');

        expect(moved, lessThan(kUnchangedRatioCeiling));
      },
      skip: skipReason,
    );

    test(
      'the runtime appends to the surface filter rather than replacing it',
      () async {
        // Load-bearing, not a restatement. Substituting the filter instead of
        // appending it was injected and measured: the bucket count stayed at
        // 20 and `movedRatio` stayed at 0.198 — over the floor. The judgement
        // above would have passed while the Tier 1 blur was gone, which is the
        // large, confident, wrong number this whole probe exists to avoid.
        await page.evaluate<void>("() => window.__showOnly('wide')");
        await _settle(page);
        final before = await page.evaluate<String>(
          '() => '
          "getComputedStyle(document.getElementById('wide')).backdropFilter",
        );

        await page.evaluate<void>(
          '() => { window.__detach_wide = '
          "window.couiAttachRefraction('wide', $_kWideBezel); }",
        );
        await _settle(page);
        final after = await page.evaluate<String>(
          "() => document.getElementById('wide').style.backdropFilter",
        );

        stdout.writeln('W3-append  before="$before"  after="$after"');

        expect(before, isNot('none'), reason: 'the surface had no base filter');
        expect(after, startsWith(before));
        expect(after, contains('url('));
      },
      skip: skipReason,
    );

    test(
      'detaching removes what it added, and remounting does not stack',
      () async {
        // A surface that unmounts must not leave the page holding a filter
        // element and an inline override for an element nobody is driving any
        // more. The failure is quiet — the surface still looks right, and the
        // document accumulates one dead `<svg>` per mount.
        await page.evaluate<void>("() => window.__showOnly('wide')");
        await _settle(page);
        final before = await _shootPanel(page);
        final filtersBefore = await page.evaluate<int>(
          "() => document.querySelectorAll('filter').length",
        );

        await page.evaluate<void>(
          '() => { window.__detach_wide = '
          "window.couiAttachRefraction('wide', $_kWideBezel); }",
        );
        await _settle(page);

        // Without this pair the test is vacuous: a runtime that attached
        // nothing would leave the filter count at zero and the pixels
        // unchanged, and "it cleaned up after itself" would pass on the
        // strength of never having made anything.
        final attached = await _shootPanel(page);
        final filtersAttached = await page.evaluate<int>(
          "() => document.querySelectorAll('filter').length",
        );

        await page.evaluate<void>('() => window.__detach_wide()');
        await _settle(page);

        final after = await _shootPanel(page);
        final filtersAfter = await page.evaluate<int>(
          "() => document.querySelectorAll('filter').length",
        );

        stdout.writeln(
          'W3-detach  attached=${diffRatio(before, attached).toStringAsFixed(4)}'
          '  restored=${diffRatio(before, after).toStringAsFixed(4)}'
          '  filters=$filtersBefore→$filtersAttached→$filtersAfter',
        );

        expect(diffRatio(before, attached), greaterThan(kMovedRatioFloor));
        expect(filtersAttached, greaterThan(filtersBefore));

        expect(diffRatio(before, after), lessThan(kUnchangedRatioCeiling));
        expect(filtersAfter, filtersBefore);

        // Restoring the inline value is not what the pixels above prove —
        // that was injected and measured. Removing the filter element leaves
        // the `url()` dangling, and Chromium ignores a dangling piece while
        // still applying the rest of the chain, so the surface looks correct
        // either way.
        //
        // What it costs is the next mount: a fresh runtime reads the computed
        // style to learn its base, and a base still carrying the last mount's
        // reference means every remount folds another one in. So the claim
        // that has teeth is that re-attaching yields exactly one.
        await page.evaluate<void>(
          '() => { window.__detach_wide = '
          "window.couiAttachRefraction('wide', $_kWideBezel); }",
        );
        await _settle(page);
        final reattached = await page.evaluate<String>(
          "() => document.getElementById('wide').style.backdropFilter",
        );

        stdout.writeln('W3-remount  inline="$reattached"');

        expect('url('.allMatches(reattached).length, 1);
      },
      skip: skipReason,
    );

    test(
      'a browser that cannot draw the filter keeps its blur and is handed none',
      () async {
        // WebKit and Gecko accept `url()` in a `backdrop-filter` list and then
        // draw nothing for the whole list, the surface's blur and lift
        // included. Chromium draws the same pixels whatever it is told it is,
        // so the verdict is not a picture of Safari — it is what the shipped
        // runtime *writes* when the page says it is one: no reference, no
        // filter element, and the stylesheet's chain left to blur the pane.
        //
        // Every user agent of the table `coui_core` pins is tried, so a browser
        // added to the answer without the runtime following, or the other way
        // round, fails here under its own name.
        final cases = _browserCases();
        // A table that lost its rows would pass every loop below.
        expect(cases.length, greaterThanOrEqualTo(15));
        final file = p.join(tempDir.path, 'runtime.html');

        for (final each in cases) {
          final userAgent = each['userAgent']! as String;
          // A server has no browser to impersonate.
          if (userAgent.isEmpty) continue;

          final name = each['name']! as String;
          final renders = each['renders']! as bool;
          final other = await browser.newPage();
          await other.setUserAgent(userAgent);
          await other.goto(Uri.file(file).toString(), wait: Until.load);
          await _settle(other);
          await other.evaluate<void>('() => window.couiResetRefractionCache()');
          await other.evaluate<void>("() => window.__showOnly('wide')");
          await _settle(other);
          final base = await other.evaluate<String>(
            '() => '
            "getComputedStyle(document.getElementById('wide')).backdropFilter",
          );

          await other.evaluate<void>(
            '() => { window.__detach_wide = '
            "window.couiAttachRefraction('wide', $_kWideBezel); }",
          );
          await _settle(other);
          final inline = await other.evaluate<String>(
            "() => document.getElementById('wide').style.backdropFilter",
          );
          final filters = await other.evaluate<int>(
            "() => document.querySelectorAll('filter').length",
          );
          final buckets = luminanceBuckets(await _shootPanel(other));
          await other.close();

          stdout.writeln(
            'W3-browser  renders=$renders  inline="$inline"  filters=$filters'
            '  buckets=$buckets  $name',
          );

          // The premise, under every user agent: the stylesheet blurs the pane.
          expect(base, contains('blur('), reason: '$name: no base blur');
          if (renders) {
            expect(
              inline,
              contains('url('),
              reason: '$name: a browser that draws the filter is handed it',
            );
            expect(filters, greaterThan(0), reason: name);
          } else {
            expect(
              inline,
              isEmpty,
              reason: '$name: a browser that cannot draw it is handed nothing',
            );
            expect(filters, 0, reason: '$name: no filter element is built');
            expect(
              buckets,
              greaterThan(kBlurBucketFloor),
              reason: '$name: the pane must still be a blurred surface',
            );
          }
        }
      },
      skip: skipReason,
    );
  });

  group('the displacement map is generated once per geometry', () {
    late Browser browser;
    late Page page;
    late Directory tempDir;
    late String compiledJs;

    setUpAll(() async {
      if (chromePath == null) return;
      final buildDir = Directory.systemTemp.createTempSync('refraction-build-');
      final output = p.join(buildDir.path, 'runtime.js');
      final result = Process.runSync('dart', [
        'compile',
        'js',
        '-O2',
        '-o',
        output,
        _kEntryPath,
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      compiledJs = File(output).readAsStringSync();
      buildDir.deleteSync(recursive: true);

      browser = await launchCaptureBrowser(
        width: _kViewportWidth,
        height: _kViewportHeight,
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
      tempDir = Directory.systemTemp.createTempSync('refraction-cache-');
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '${_bodyHtml()}<script>$compiledJs</script>',
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        surfaceStyleId: 'liquidGlass',
      );
      final file = File(p.join(tempDir.path, 'cache.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: Until.load);
      await _settle(page);
      await page.evaluate<void>('() => window.couiResetRefractionCache()');
    });

    tearDown(() async {
      if (chromePath == null) return;
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    Future<int> cacheSize() =>
        page.evaluate<int>('() => window.couiRefractionCacheSize()');

    test(
      'a second surface of the same geometry generates nothing new',
      () async {
        await _attachAndShoot(page, 'wide', bezel: _kWideBezel);
        final afterFirst = await cacheSize();

        await _attachAndShoot(page, 'twin', bezel: _kWideBezel);
        final afterSecond = await cacheSize();

        stdout.writeln('W3-cache  first=$afterFirst  second=$afterSecond');

        // The claim: re-entry at a known geometry costs no regeneration.
        // Generating is a full canvas readback per surface, so a cache that
        // missed would be invisible in the pixels and expensive in the frame.
        expect(afterFirst, 1);
        expect(afterSecond, afterFirst);
      },
      skip: skipReason,
    );

    test(
      'and a different bezel at the same size does generate one',
      () async {
        // The falsifier for the test above. A cache that answered every
        // lookup with whatever it generated first would pass that one and be
        // catastrophically wrong — it would hand a surface the map built for
        // different geometry. Bezel is in the key precisely so this grows.
        await _attachAndShoot(page, 'wide', bezel: _kWideBezel);
        await _attachAndShoot(page, 'narrow', bezel: _kNarrowBezel);

        expect(await cacheSize(), 2);
      },
      skip: skipReason,
    );

    test(
      'and a resized surface regenerates for its new rectangle',
      () async {
        await _attachAndShoot(page, 'resized', bezel: _kWideBezel);
        expect(await cacheSize(), 1);

        // Size is why this cannot ride the theme axis: the map is a function
        // of the measured rectangle, so the surface has to be re-baked when
        // that rectangle changes. The `ResizeObserver` is what notices.
        await page.evaluate<void>(
          "() => { document.getElementById('resized').style.width = '160px'; }",
        );
        await _settle(page);
        await _settle(page);

        expect(await cacheSize(), 2);
      },
      skip: skipReason,
    );
  });
}

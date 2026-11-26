// The terms of the glass an app can state per mode, judged in a real browser.
//
// `surface_mode_css_test.dart` reads the stylesheet as text and proves what it
// says. A stylesheet is read by a browser that matches selectors, so a rule
// can be correct as text and never apply — and the other half of the claim is
// not CSS at all: the per-element runtime has to follow a palette switch that
// rebuilds nothing, and it has to bake the rim and the displacement map from
// what the app stated rather than from the preset. Neither is visible without
// a document that changes under a running host.
//
// ## Everything here drives the shipped code
//
// The page carries the compiled host (`surface_mode_entry.dart`), and the
// stylesheet comes from `ThemeConfig` — a hand-copied sheet would make every
// verdict a statement about the copy.
//
// ## What each verdict is, and what it was injected against
//
//   lift per palette     the computed `backdrop-filter` of a surface in a
//                        light page, a dark page, and a scope of the other
//                        palette inside each. Read from the browser's cascade,
//                        so a selector that never matches fails here.
//   host follows palette the inline filter after `data-theme` flips under an
//                        installed host. A host that kept its attachment
//                        leaves the old palette's dimming and lift inline,
//                        where they outrank the stylesheet.
//   rim per palette      the sweeps the runtime wrote, against the strings
//                        Core builds for the same box, and the sweep the
//                        browser then paints in each palette.
//   the law              pixels: the same panel under the default law and the
//                        stated one differs, and under the default law stated
//                        twice it does not. The sheet that states the law
//                        paints nothing else.
//   no leak              a surface of another style nested in a tuned one
//                        reads none of its statements.
//
// A run with no Chrome on the machine is skipped, not zeroed.
import 'dart:convert';
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

const _kViewportWidth = 400;
const _kViewportHeight = 300;

const _kPanelLeft = 100;
const _kPanelTop = 75;
const _kPanelWidth = 200;
const _kPanelHeight = 150;
const _kPanelRadius = 24;

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

/// The panel under judgement, and the small surfaces the other verdicts read.
///
/// The small ones sit above the panel's capture clip so the pixel verdicts see
/// only the panel. `display: contents` on the palette wrappers keeps them out
/// of layout while the attribute still matches the stylesheet's selectors.
///
/// `--coui-surface-rgb` is written inline because it is deliberately absent
/// from the stylesheet: every component publishes it from whichever token it
/// chose, and without it `background-color` is invalid.
const String _kBodyHtml =
    '''
<style>
  body { margin: 0; width: ${_kViewportWidth}px; height: ${_kViewportHeight}px; }
  #bg { position: absolute; inset: 0;
        background: repeating-linear-gradient(90deg,
          #000 0 12px, #fff 12px 24px); }
  .panel { position: absolute; top: ${_kPanelTop}px; left: ${_kPanelLeft}px;
           width: ${_kPanelWidth}px; height: ${_kPanelHeight}px;
           border-radius: ${_kPanelRadius}px; }
  .small { position: absolute; top: 10px; width: 60px; height: 40px;
           border-radius: 12px; }
  .wrap { display: contents; }
</style>
<div id="bg"></div>
<div id="p" class="panel coui-surface coui-surface-functional"
     style="--coui-surface-rgb: var(--coui-surface);"></div>
<div class="wrap" data-theme="dark">
  <div id="inDark" class="small coui-surface coui-surface-functional"
       style="left: 10px; --coui-surface-rgb: var(--coui-surface);"></div>
</div>
<div class="wrap" data-theme="light">
  <div id="inLight" class="small coui-surface coui-surface-functional"
       style="left: 80px; --coui-surface-rgb: var(--coui-surface);"></div>
</div>
<div id="local"
     class="small coui-material-surface coui-surface-functional
            coui-material-liquidGlass"
     style="left: 150px; --coui-surface-rgb: var(--coui-surface);"></div>
<div id="outer" class="small coui-surface coui-surface-functional"
     style="left: 220px; width: 120px; height: 50px;
            --coui-surface-rgb: var(--coui-surface);">
  <div id="inner"
       class="coui-material-surface coui-surface-functional
              coui-material-neoBrutalism"
       style="position: absolute; left: 10px; top: 10px; width: 40px;
              height: 20px;"></div>
</div>
''';

Future<void> _settle(Page page) async {
  await page.evaluate<void>(
    '() => new Promise(function (done) { requestAnimationFrame(function () '
    '{ requestAnimationFrame(done); }); })',
  );
}

/// Polls [condition] (a JS expression) until it holds, and says whether it
/// did within [within].
///
/// The host answers a mutation on the next frame, so a fixed sleep is either
/// too short (flaky) or long enough to hide a host that is merely slow. A
/// verdict that the condition *never* held is what a stale host looks like.
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

double? _numberIn(String filter, String fn) {
  final match = RegExp('$fn\\(([0-9.]+)\\)').firstMatch(filter);

  return match == null ? null : double.parse(match.group(1)!);
}

String _inlineFilter(String id) =>
    "document.getElementById('$id').style.backdropFilter";

String _computedFilter(String id) =>
    "getComputedStyle(document.getElementById('$id')).backdropFilter";

Future<String> _read(Page page, String expression) async =>
    await page.evaluate<String>('() => String($expression)');

/// What the browser paints on the panel's rim.
const String _kRimPaint = '''
getComputedStyle(document.getElementById('p'), '::before')
  .backgroundImage''';

/// The data URL of the first displacement map in the document.
const String _kFirstMapHref = '''
(function () {
  const m = document.querySelector('filter feImage');
  return m ? (m.getAttribute('href') || m.getAttribute('xlink:href')) : '';
})()''';

CoreSurfaceEdgeBevel get _presetBevel =>
    CoreSurfaceRecipe.of(_glass).functionalSurface!.sheen!.bevel!;

/// The sweep Core builds for the panel at [angle], spelled the way the
/// runtime spells it.
String _expectedSweep(double angle) => surfaceEdgeRimSweepCss(
  _presetBevel.relit(angle: angle),
  width: _kPanelWidth.toDouble(),
  height: _kPanelHeight.toDouble(),
  radius: _kPanelRadius.toDouble(),
);

/// The stop angles of a `conic-gradient`, in the order they are painted.
///
/// The start (`from 0deg at 50% 50%`) is not a stop, and a browser that
/// serialises a computed gradient leaves it out because it is the default —
/// so it is removed from both spellings before the angles are read.
List<double> _stops(String gradient) {
  final stops = gradient.replaceFirst(
    RegExp('from [0-9.]+deg( at [^,]+)?'),
    '',
  );

  return [
    for (final match in RegExp(r'([0-9]+(?:\.[0-9]+)?)deg').allMatches(stops))
      double.parse(match.group(1)!),
  ];
}

void main() {
  final chromePath = _systemChromePath();
  final skipReason = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

  group('the per-mode terms of the glass, judged in a browser', () {
    late Browser browser;
    late Directory buildDir;
    late String compiledJs;
    var pageCount = 0;

    setUpAll(() async {
      if (chromePath == null) return;

      buildDir = Directory.systemTemp.createTempSync('surface-mode-');
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
      String? userAgent,
    }) async {
      final page = await browser.newPage();
      if (userAgent != null) await page.setUserAgent(userAgent);
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '$_kBodyHtml<script>$compiledJs</script>',
        themeConfig: ThemeConfig.from(
          CouiColorPresets.source,
          surfaceTunings: {_glass: tuning},
        ),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        theme: theme,
        surfaceStyleId: _glass.name,
      );
      final file = File(p.join(buildDir.path, 'page-${pageCount++}.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: Until.load);
      await _settle(page);

      return page;
    }

    Future<void> install(Page page) async {
      await page.evaluate<void>('() => window.couiInstallSurfaceHost()');
      await _settle(page);
    }

    Future<void> setTheme(Page page, String theme) async {
      await page.evaluate<void>(
        "() => document.documentElement.setAttribute('data-theme', '$theme')",
      );
      await _settle(page);
    }

    const lifts = CoreSurfaceTuning(
      surfaceSaturation: 1.3,
      surfaceSaturationInDarkMode: 1.9,
    );

    final recipe = CoreSurfaceRecipe.of(_glass);
    final dimming = recipe.functionalSurface!.backdropBrightness;

    test(
      'the lift of each palette is the one the browser matches',
      () async {
        final page = await open(lifts);

        // Light page: the surface is light, a scope of the dark palette
        // inside it is dark.
        expect(
          _numberIn(await _read(page, _computedFilter('p')), 'saturate'),
          1.3,
        );
        expect(
          _numberIn(await _read(page, _computedFilter('inDark')), 'saturate'),
          1.9,
          reason: 'a dark scope in a light page draws the dark lift',
        );
        expect(
          _numberIn(await _read(page, _computedFilter('inDark')), 'brightness'),
          dimming.dark,
          reason: 'and the dimming it always drew',
        );

        // Dark page: the other way round.
        await setTheme(page, 'dark');
        expect(
          _numberIn(await _read(page, _computedFilter('p')), 'saturate'),
          1.9,
        );
        expect(
          _numberIn(await _read(page, _computedFilter('p')), 'brightness'),
          dimming.dark,
        );
        expect(
          _numberIn(await _read(page, _computedFilter('inLight')), 'saturate'),
          1.3,
          reason: 'a light scope in a dark page draws the light lift',
        );

        // And back: nothing is latched.
        await setTheme(page, 'light');
        expect(
          _numberIn(await _read(page, _computedFilter('p')), 'saturate'),
          1.3,
        );
        await page.close();
      },
      skip: skipReason,
    );

    test(
      'a surface of its own style follows the OS preference',
      () async {
        // The media form: no palette attribute anywhere, the OS decides.
        final page = await open(lifts);
        await page.evaluate<void>(
          "() => document.documentElement.removeAttribute('data-theme')",
        );

        await page.devTools.emulation.setEmulatedMedia(
          features: [
            protocol.MediaFeature(name: 'prefers-color-scheme', value: 'dark'),
          ],
        );
        await _settle(page);
        expect(
          _numberIn(await _read(page, _computedFilter('local')), 'saturate'),
          1.9,
        );

        await page.devTools.emulation.setEmulatedMedia(
          features: [
            protocol.MediaFeature(name: 'prefers-color-scheme', value: 'light'),
          ],
        );
        await _settle(page);
        expect(
          _numberIn(await _read(page, _computedFilter('local')), 'saturate'),
          1.3,
        );
        await page.close();
      },
      skip: skipReason,
    );

    test(
      'the host re-binds when the palette changes under it',
      () async {
        // The runtime appends its filter to the list the stylesheet computed
        // for the palette it attached under, and writes it inline — where it
        // outranks the other palette's rules. A host that never looked at the
        // palette leaves that palette's dimming and lift on the surface after
        // a switch that rebuilt nothing.
        final page = await open(lifts);
        await install(page);

        Future<({double? lift, double? dim, bool bent})> inline(
          String id,
        ) async {
          final filter = await _read(page, _inlineFilter(id));

          return (
            lift: _numberIn(filter, 'saturate'),
            dim: _numberIn(filter, 'brightness'),
            bent: filter.contains('url('),
          );
        }

        final light = await inline('p');
        stdout.writeln('H4-host light  $light');
        expect(light.bent, isTrue, reason: 'the premise: the host bent it');
        expect(light.lift, 1.3);
        expect(light.dim, dimming.light);

        // A scope of the other palette, attached once at mount.
        final scoped = await inline('inDark');
        expect(scoped.lift, 1.9);
        expect(scoped.dim, dimming.dark);

        await setTheme(page, 'dark');
        final followed = await _holds(
          page,
          "${_inlineFilter('p')}.includes('saturate(1.9)') && "
          "${_inlineFilter('p')}.includes('url(')",
        );
        final dark = await inline('p');
        stdout.writeln('H4-host dark   $dark  followed=$followed');
        expect(followed, isTrue, reason: 'the host kept the light attachment');
        expect(dark.lift, 1.9);
        expect(dark.dim, dimming.dark);
        expect(dark.bent, isTrue);
        expect(
          'url('.allMatches(await _read(page, _inlineFilter('p'))).length,
          1,
          reason: 'one bend, not one per palette',
        );

        // The scope that was dark from the start is still dark; the light
        // one did not move.
        expect((await inline('inDark')).lift, 1.9);

        await setTheme(page, 'light');
        expect(
          await _holds(
            page,
            "${_inlineFilter('p')}.includes('saturate(1.3)')",
          ),
          isTrue,
        );
        await page.close();
      },
      skip: skipReason,
    );

    test(
      'and when only the OS preference changes',
      () async {
        // A surface whose nearest palette is nobody's attribute is driven by
        // the OS, and a change of it writes nothing to the document at all.
        final page = await open(lifts);
        await page.evaluate<void>(
          "() => document.documentElement.removeAttribute('data-theme')",
        );
        // Stated rather than assumed: a machine set to a dark appearance
        // starts the page dark, and the premise below is the light one.
        await page.devTools.emulation.setEmulatedMedia(
          features: [
            protocol.MediaFeature(name: 'prefers-color-scheme', value: 'light'),
          ],
        );
        await _settle(page);
        await install(page);
        expect(
          _numberIn(await _read(page, _inlineFilter('local')), 'saturate'),
          1.3,
          reason: 'the premise: attached under the light preference',
        );

        await page.devTools.emulation.setEmulatedMedia(
          features: [
            protocol.MediaFeature(name: 'prefers-color-scheme', value: 'dark'),
          ],
        );
        final followed = await _holds(
          page,
          "${_inlineFilter('local')}.includes('saturate(1.9)') && "
          "${_inlineFilter('local')}.includes('url(')",
        );
        stdout.writeln(
          'H4-host os     ${await _read(page, _inlineFilter('local'))}',
        );
        expect(followed, isTrue, reason: 'the host ignored the OS preference');
        await page.close();
      },
      skip: skipReason,
    );

    test(
      'a browser that cannot draw the filter keeps its blur and its rim, '
      'and is handed no reference',
      () async {
        // WebKit and Gecko accept `url()` in a `backdrop-filter` list and then
        // draw nothing for the whole list, the surface's blur and lift
        // included. Chromium draws the same pixels whatever it is told it is,
        // so the verdict is not a picture of Safari — it is what the shipped
        // host *writes* when the page says it is one: no reference, no filter
        // element, the stylesheet's lift still the one that applies, and the
        // rim — which is CSS, and which every browser draws — still there. And
        // once settled the host leaves the surface alone: a host that had
        // counted on a bend it never got would find its filter missing on every
        // pass and build the attachment again each time, which shows as a new
        // `ResizeObserver` for every style write on the surface.
        //
        // Every user agent of the table `coui_core` pins is tried, so a browser
        // added to the answer without the host following, or the other way
        // round, fails here under its own name.
        final cases = _browserCases();
        // A table that lost its rows would pass every loop below.
        expect(cases.length, greaterThanOrEqualTo(15));

        for (final each in cases) {
          final userAgent = each['userAgent']! as String;
          // A server has no browser to impersonate.
          if (userAgent.isEmpty) continue;

          final name = each['name']! as String;
          final renders = each['renders']! as bool;
          final page = await open(lifts, userAgent: userAgent);
          await page.evaluate<void>('''
() => {
  window.__observers = 0;
  const Native = window.ResizeObserver;
  window.ResizeObserver = class extends Native {
    constructor(callback) { super(callback); window.__observers++; }
  };
}''');
          await install(page);
          // Several frames, so a host that was still rebuilding is seen.
          for (var i = 0; i < 6; i++) {
            await _settle(page);
          }
          final settled = await page.evaluate<int>('() => window.__observers');
          // Writes that are not the host's own, on the surface it tracks.
          for (var i = 0; i < 5; i++) {
            await page.evaluate<void>(
              "() => { document.getElementById('p').style.opacity = "
              "'${i.isEven ? 0.99 : 1}'; }",
            );
            await _settle(page);
          }
          final rebuilt = await page.evaluate<int>('() => window.__observers');

          final inline = await _read(page, _inlineFilter('p'));
          final computed = await _read(page, _computedFilter('p'));
          final filters = await page.evaluate<int>(
            "() => document.querySelectorAll('filter').length",
          );
          final rim = await _read(
            page,
            "document.getElementById('p').style"
            ".getPropertyValue('--coui-surface-rim-sweep')",
          );
          await page.close();

          stdout.writeln(
            'H4-browser  renders=$renders  inline="$inline"  filters=$filters'
            '  observers=$settled→$rebuilt  $name',
          );

          // The premise, under every user agent: the surface is a lifted blur,
          // and the host drew its rim.
          expect(
            rebuilt,
            settled,
            reason: '$name: a settled host rebuilt its attachment',
          );
          expect(
            _numberIn(computed, 'saturate'),
            1.3,
            reason: '$name: the stylesheet states the light lift',
          );
          expect(rim, isNotEmpty, reason: '$name: the host drew no rim');
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
              isNot(contains('url(')),
              reason: '$name: a browser that cannot draw it is handed nothing',
            );
            expect(filters, 0, reason: '$name: no filter element is built');
          }
        }
      },
      skip: skipReason,
    );

    group('the rim is lit from the direction of the palette', () {
      Future<({String light, String dark})> sweeps(Page page) async => (
        light: await _read(
          page,
          "document.getElementById('p').style"
          ".getPropertyValue('--coui-surface-rim-sweep')",
        ),
        dark: await _read(
          page,
          "document.getElementById('p').style"
          ".getPropertyValue('--coui-surface-rim-sweep-dark')",
        ),
      );

      /// The stops the browser paints on the panel's rim.
      Future<List<double>> painted(Page page) async => _stops(
        await _read(page, _kRimPaint),
      );

      test(
        'each palette gets the sweep of its own angle',
        () async {
          final page = await open(
            const CoreSurfaceTuning(lightAngle: -30, lightAngleInDarkMode: -60),
          );
          await install(page);

          final got = await sweeps(page);
          stdout.writeln(
            'H4-rim light=${got.light.length} dark=${got.dark.length}',
          );
          expect(got.light, _expectedSweep(-30));
          expect(got.dark, _expectedSweep(-60));
          expect(got.light, isNot(got.dark), reason: 'the premise');

          // What the browser paints, which is the cascade choosing between
          // the two strings above.
          final lightStops = _stops(_expectedSweep(-30));
          final darkStops = _stops(_expectedSweep(-60));
          expect(await painted(page), lightStops);

          await setTheme(page, 'dark');
          expect(await painted(page), darkStops);

          await setTheme(page, 'light');
          expect(await painted(page), lightStops);
          await page.close();
        },
        skip: skipReason,
      );

      test(
        'a dark angle alone leaves light where the preset has it',
        () async {
          final page = await open(
            const CoreSurfaceTuning(lightAngleInDarkMode: -60),
          );
          await install(page);

          final got = await sweeps(page);
          expect(got.light, _expectedSweep(_presetBevel.lightAngle));
          expect(got.dark, _expectedSweep(-60));
          await page.close();
        },
        skip: skipReason,
      );

      test(
        'one angle for both is one sweep, and no second string',
        () async {
          final page = await open(const CoreSurfaceTuning(lightAngle: -30));
          await install(page);

          final got = await sweeps(page);
          expect(got.light, _expectedSweep(-30));
          expect(got.dark, isEmpty, reason: 'nothing to choose between');

          final stops = _stops(_expectedSweep(-30));
          expect(await painted(page), stops);
          await setTheme(page, 'dark');
          expect(await painted(page), stops, reason: 'the same light in dark');
          await page.close();
        },
        skip: skipReason,
      );

      test(
        "an app that states nothing gets the preset's sweep",
        () async {
          final page = await open(CoreSurfaceTuning.none);
          await install(page);

          final got = await sweeps(page);
          expect(got.light, _expectedSweep(_presetBevel.lightAngle));
          expect(got.dark, isEmpty);
          await page.close();
        },
        skip: skipReason,
      );
    });

    group('the law of the rim', () {
      Future<img.Image> shoot(Page page) async {
        final bytes = await page.screenshot(
          clip: const Rectangle(
            _kPanelLeft,
            _kPanelTop,
            _kPanelWidth,
            _kPanelHeight,
          ),
        );

        return img.decodePng(bytes)!;
      }

      Future<img.Image> bent(CoreSurfaceTuning tuning) async {
        final page = await open(tuning);
        await install(page);
        final shot = await shoot(page);
        await page.close();

        return shot;
      }

      test(
        'stating it changes what the backdrop does, and nothing else does',
        () async {
          final base = await bent(CoreSurfaceTuning.none);
          final again = await bent(CoreSurfaceTuning.none);
          final paraxial = await bent(
            const CoreSurfaceTuning(
              refractionModel: CoreRefractionModel.paraxial,
            ),
          );
          final stated = await bent(
            const CoreSurfaceTuning(refractionModel: CoreRefractionModel.snell),
          );

          // Is the thing under judgement glass at all? A striped backdrop
          // seen flat lands in two luminance buckets; through a blur it
          // lands in a couple of dozen.
          expect(luminanceBuckets(base), greaterThan(kBlurBucketFloor));

          final noise = diffRatio(base, again);
          final restated = diffRatio(base, stated);
          final moved = diffRatio(base, paraxial);
          stdout.writeln(
            'H4-law noise=${noise.toStringAsFixed(4)} '
            'restated=${restated.toStringAsFixed(4)} '
            'moved=${moved.toStringAsFixed(4)}',
          );

          // The floor: the same page twice is the same pixels.
          expect(noise, lessThan(kUnchangedRatioCeiling));
          // Stating the law the preset already has is no statement.
          expect(restated, lessThan(kUnchangedRatioCeiling));
          // Stating the other one bends the backdrop differently.
          expect(moved, greaterThan(kMovedRatioFloor));
        },
        skip: skipReason,
      );

      test(
        'the map the filter reads is the one the law bakes',
        () async {
          Future<String> mapOf(CoreSurfaceTuning tuning) async {
            final page = await open(tuning);
            await install(page);
            final href = await _read(page, _kFirstMapHref);
            await page.close();

            return href;
          }

          final snell = await mapOf(CoreSurfaceTuning.none);
          final paraxial = await mapOf(
            const CoreSurfaceTuning(
              refractionModel: CoreRefractionModel.paraxial,
            ),
          );

          expect(snell, startsWith('data:image/png'));
          expect(paraxial, startsWith('data:image/png'));
          expect(paraxial, isNot(snell));
        },
        skip: skipReason,
      );
    });

    group('what an app states does not reach what it did not', () {
      test(
        'a surface of another style nested in a tuned one reads none of it',
        () async {
          // A custom property inherits. The inner surface is neo-brutalism,
          // which states no rim light and no law, nested in a glass surface
          // whose light and law the app moved.
          final page = await open(
            const CoreSurfaceTuning(
              lightAngle: -30,
              refractionModel: CoreRefractionModel.paraxial,
            ),
          );

          Future<List<String>> statements(String id) async => [
            for (final name in const [
              '--coui-surface-rim-angle',
              '--coui-surface-rim-angle-dark',
              '--coui-surface-refraction-model',
            ])
              (await _read(
                page,
                "getComputedStyle(document.getElementById('$id'))"
                ".getPropertyValue('$name').trim()",
              )),
          ];

          final outer = await statements('outer');
          final inner = await statements('inner');
          stdout.writeln('H4-leak outer=$outer inner=$inner');

          // One light for both palettes is a statement about each, because
          // the preset's dark light is not the one the app moved to.
          expect(outer, ['-30.0', '-30.0', 'paraxial'], reason: 'the premise');
          expect(inner, ['', '', ''], reason: 'inherited from the surface');
          await page.close();
        },
        skip: skipReason,
      );

      test(
        'an untuned page carries none of it, and the runtime writes one sweep',
        () async {
          final page = await open(CoreSurfaceTuning.none);
          await install(page);

          for (final name in const [
            '--coui-surface-rim-angle',
            '--coui-surface-rim-angle-dark',
            '--coui-surface-refraction-model',
          ]) {
            expect(
              await _read(
                page,
                "getComputedStyle(document.getElementById('p'))"
                ".getPropertyValue('$name').trim()",
              ),
              isEmpty,
              reason: name,
            );
          }
          expect(
            await _read(
              page,
              "document.querySelectorAll('[style*=\"rim-sweep-dark\"]').length",
            ),
            '0',
          );
          await page.close();
        },
        skip: skipReason,
      );
    });
  });
}

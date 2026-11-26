// The Web's adaptive quality, judged in a real Chrome.
//
// The VM tests prove what the sampler decides, what the stylesheet says and
// what the root writes on the document (`adaptive_quality_sampler_test`,
// `adaptive_quality_css_test`, `adaptive_quality_scope_test`). None of that
// says a browser runs it: the listeners, the `requestAnimationFrame` loop, the
// observers, the attribute's reach into a cascade that a real engine matches,
// and the refraction host taking the bend off a surface and giving it back are
// the browser's. This file mounts the shipped `CoUIWeb` with adaptive quality
// stated, over glass surfaces, and watches what the page does.
//
// ## What is the shipped code and what is stood in
//
// The page runs `CoUIWeb`, the feed, the sampler, the governor, the
// stylesheet from `ThemeConfig` and the refraction host — the entry only
// states the terms and reports (`adaptive_quality_entry.dart`). Two things are
// stood in because a headless Chrome cannot give them:
//
//   the load      A backdrop filter is paid for on a compositor this headless
//                 browser does not stress, so the page carries a fixed amount
//                 of computation in its own `requestAnimationFrame` callback —
//                 a few milliseconds of main-thread work per frame — and the
//                 CPU is throttled with `Emulation.setCPUThrottlingRate`. The
//                 same page is comfortable unthrottled and over budget
//                 throttled, which is the contrast the governor has to see.
//                 The load is computation and not a wait on the clock: a wait
//                 takes the same wall time however slow the processor is, so
//                 throttling would not touch it. None of this says a glass
//                 surface costs that much on any device; that is what the
//                 frame-timing harness is for.
//   the tab       `document.hidden` is overridden and `visibilitychange`
//                 dispatched; a headless run cannot hide its tab. The feed's
//                 wiring is exercised, the browser's own throttling of a
//                 hidden tab is not.
//
// ## Timing
//
// The tuning is shortened (tenths of a second where the default is seconds)
// so a verdict takes seconds. The numbers the governor judges by are not
// changed: the budget is a 60 Hz display's, the thresholds are the shipped
// ones. A machine that cannot deliver a steady 60 fps to an empty page makes
// every timing verdict noise, so those are skipped with the measurement that
// said so, not run.
//
// A run with no Chrome on the machine is skipped, not zeroed.
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:puppeteer/protocol/emulation.dart' as protocol;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

const String _kEntryPath = 'tool/parity/src/web/adaptive_quality_entry.dart';

const int _kViewportWidth = 480;
const int _kViewportHeight = 260;

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

/// The governor's numbers, in tenths of a second: a window is eighteen frames
/// at 60 Hz. Everything not named is the shipped default.
const Map<String, Object?> _kQuick = {
  'skipSeconds': 0.2,
  'warmupSeconds': 0.5,
  'windowSeconds': 0.3,
  'cooldownSeconds': 0.8,
  'settleSeconds': 0.1,
  'sampleGraceSeconds': 1.0,
  'degradeWindows': 1,
  'recoverWindows': 3,
  'probationWindows': 2,
  'maxBackoffDoublings': 1,
};

/// Terms that measure against a 60 Hz budget with the shortened numbers.
const Map<String, Object?> _kMeasuring = {
  'targetFrameRate': 60,
  'tuning': _kQuick,
};

/// A load that costs a fixed amount of work, a counter of the frames the
/// *library* asks for, and a synthetic pointer.
///
/// The counter wraps `requestAnimationFrame` before any library script runs,
/// and the load loop uses the original, so the counter says what the feed, the
/// host and the framework ask for and not what the load does.
///
/// The load is work, not waiting: a fixed amount of computation, sized so that
/// it takes `ms` milliseconds on an unthrottled processor. A loop that waits
/// for the wall clock takes `ms` however slow the processor is, so throttling
/// would not touch it.
const String _kPrelude = '''
<script>
(function () {
  var raf = window.requestAnimationFrame.bind(window);
  window.__rawRaf = raf;
  window.__rafCalls = 0;
  window.requestAnimationFrame = function (cb) {
    window.__rafCalls++;
    return raf(cb);
  };
  var perMs = 0;
  var work = 0;
  var loading = false;
  function compute(n) {
    var x = 0;
    for (var i = 0; i < n; i++) x += Math.sqrt(i) * 1.0001;
    window.__sink = x;
  }
  function calibrate() {
    compute(2e5);
    var n = 1e5;
    for (;;) {
      var t = performance.now();
      compute(n);
      var spent = performance.now() - t;
      if (spent > 8) { perMs = n / spent; return; }
      n *= 2;
    }
  }
  function tick() {
    if (!loading) return;
    compute(work);
    raf(tick);
  }
  window.couiLoad = function (ms) {
    if (ms > 0 && perMs === 0) calibrate();
    work = Math.round(ms * perMs);
    if (ms > 0 && !loading) { loading = true; raf(tick); }
    if (ms <= 0) loading = false;
  };
  var timer = null;
  window.couiMoving = function (on) {
    clearInterval(timer);
    if (on) {
      timer = setInterval(function () {
        document.dispatchEvent(new Event('pointermove'));
      }, 250);
    }
  };
})();
</script>
''';

/// 120 intervals between `requestAnimationFrame` callbacks of a page doing
/// nothing — what the machine can give a page before the probe asks for more.
const String _kSampleIntervals =
    '() => new Promise(function (done) {'
    ' var out = [], last = null;'
    ' function frame(t) {'
    '   if (last !== null) out.push(t - last);'
    '   last = t;'
    '   if (out.length < 120) requestAnimationFrame(frame);'
    '   else done(out);'
    ' }'
    ' requestAnimationFrame(frame);'
    ' })';

/// Tells the document its tab is hidden.
const String _kHide =
    '() => {'
    " Object.defineProperty(document, 'hidden', {"
    '   configurable: true, get: function () { return true; }'
    ' });'
    " document.dispatchEvent(new Event('visibilitychange'));"
    ' }';

/// Tells the document its tab is visible again.
const String _kShow =
    '() => {'
    ' delete document.hidden;'
    " document.dispatchEvent(new Event('visibilitychange'));"
    ' }';

/// Whether this browser reports long animation frames.
const String _kSupportsLoaf =
    '() => PerformanceObserver.supportedEntryTypes '
    ".includes('long-animation-frame')";

/// 120 ms of work in one frame, and no input of any kind.
const String _kLongFrame =
    '() => window.__rawRaf(function () {'
    ' var t = performance.now();'
    ' while (performance.now() - t < 120) {}'
    ' })';

const String _kTierAttribute =
    "document.documentElement.getAttribute('data-coui-quality')";

const String _kSurfaceBent =
    "document.getElementById('s0').style.backdropFilter.includes('url(')";

void main() {
  final chromePath = _systemChromePath();
  final noChrome = chromePath == null
      ? 'no local Chrome — adaptive quality cannot be judged in a browser here'
      : null;

  group(
    'adaptive quality on the Web, in Chrome',
    () {
      late pptr.Browser browser;
      late Directory fixture;
      late String entryJs;
      var pageCount = 0;
      // Why the timing verdicts cannot be trusted on this machine, or null.
      String? unsteady;

      setUpAll(() async {
        if (chromePath == null) return;

        fixture = Directory.systemTemp.createTempSync('coui-adaptive-quality-');
        final js = '${fixture.path}/entry.js';
        final result = await Process.run(Platform.resolvedExecutable, [
          'compile',
          'js',
          '-O2',
          '-o',
          js,
          _kEntryPath,
        ]);
        expect(
          result.exitCode,
          0,
          reason: 'compiling the probe entry failed:\n${result.stderr}',
        );
        entryJs = File(js).readAsStringSync();
        browser = await launchCaptureBrowser(
          width: _kViewportWidth,
          height: _kViewportHeight,
          executablePath: chromePath,
        );

        // Can this machine hand an empty page a steady 60 fps? If it cannot,
        // a "comfortable" phase is not comfortable and the verdicts that
        // depend on it say nothing.
        final page = await browser.newPage();
        await page.goto('about:blank');
        final intervals = (await page.evaluate<List<dynamic>>(
          _kSampleIntervals,
        )).cast<num>().map((n) => n.toDouble()).toList()..sort();
        await page.close();
        final median = intervals[intervals.length ~/ 2];
        final p95 = intervals[(intervals.length * 0.95).ceil() - 1];
        stdout.writeln(
          'AQ-calibration empty page: median '
          '${median.toStringAsFixed(2)} ms, p95 ${p95.toStringAsFixed(2)} ms',
        );
        if (median < 15 || median > 18.5 || p95 > 25) {
          unsteady =
              'an empty page gets frames every ${median.toStringAsFixed(1)} ms '
              '(p95 ${p95.toStringAsFixed(1)} ms) here, not a steady 16.7 ms';
        }
      });

      tearDownAll(() async {
        if (chromePath == null) return;
        await browser.close();
        fixture.deleteSync(recursive: true);
      });

      /// A page with the terms [stated] (or none), settled.
      Future<pptr.Page> open({
        Map<String, Object?>? stated,
        int surfaces = 4,
      }) async {
        final page = await browser.newPage();
        final options = jsonEncode({'stated': stated, 'surfaces': surfaces});
        final content = buildOfflineTailwindHarnessHtml(
          bodyHtml:
              '<script>window.couiQualityOptions = ${jsonEncode(options)}; '
              '</script>$_kPrelude<script>$entryJs</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          surfaceStyleId: 'liquidGlass',
        ).replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
        final file = File('${fixture.path}/page-${pageCount++}.html')
          ..writeAsStringSync(content);
        await page.goto(Uri.file(file.path).toString(), wait: pptr.Until.load);
        await page.waitForFunction("() => !!document.getElementById('s0')");

        return page;
      }

      /// Polls [condition] (a JS expression) until it holds, and says whether
      /// it did within [within].
      Future<bool> holds(
        pptr.Page page,
        String condition, {
        Duration within = const Duration(seconds: 8),
      }) async {
        final deadline = DateTime.now().add(within);
        while (DateTime.now().isBefore(deadline)) {
          if (await page.evaluate<bool>('() => !!($condition)')) return true;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        return false;
      }

      Future<String?> tier(pptr.Page page) =>
          page.evaluate<String?>('() => $_kTierAttribute');

      Future<List<Map<String, Object?>>> changes(pptr.Page page) async {
        final json = await page.evaluate<String>('() => couiQualityChanges()');

        return (jsonDecode(json) as List).cast<Map<String, Object?>>();
      }

      Future<List<String>> reached(pptr.Page page) async => [
        for (final change in await changes(page)) change['to']! as String,
      ];

      Future<bool> bent(pptr.Page page) =>
          page.evaluate<bool>('() => $_kSurfaceBent');

      Future<String> filter(pptr.Page page) => page.evaluate<String>(
        "() => getComputedStyle(document.getElementById('s0')).backdropFilter",
      );

      /// The alpha the browser paints the fill with.
      Future<double> fillAlpha(pptr.Page page) async {
        final color = await page.evaluate<String>(
          "() => getComputedStyle(document.getElementById('s0')) "
          '.backgroundColor',
        );
        final match = RegExp(r'rgba?\(([^)]*)\)').firstMatch(color);
        expect(match, isNotNull, reason: 'a colour, not "$color"');
        final parts = match!.group(1)!.split(RegExp('[,/ ]+'))
          ..removeWhere((part) => part.isEmpty);

        return parts.length >= 4 ? double.parse(parts[3]) : 1;
      }

      Future<int> rafCalls(pptr.Page page) =>
          page.evaluate<int>('() => window.__rafCalls');

      /// How many frames the library asks for over [span].
      Future<int> framesAsked(pptr.Page page, Duration span) async {
        final before = await rafCalls(page);
        await Future<void>.delayed(span);

        return await rafCalls(page) - before;
      }

      Future<void> throttle(pptr.Page page, num rate) =>
          page.devTools.emulation.setCPUThrottlingRate(rate);

      Future<void> state(pptr.Page page, Map<String, Object?>? stated) {
        final json = stated == null ? null : jsonEncode(stated);

        return page.evaluate<void>(
          '(json) => couiQualityState(json)',
          args: [json],
        );
      }

      /// The premise every verdict about the bend leans on.
      Future<void> expectBentAtFull(pptr.Page page) async {
        expect(
          await holds(page, _kSurfaceBent),
          isTrue,
          reason: 'the premise: the shipped host bent the surface',
        );
      }

      /// Waits for the fill to be painted at [alpha]; the sheet fades a fill
      /// between tiers, so it is read once it has stopped.
      Future<bool> fillBecomes(pptr.Page page, double alpha) async {
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (DateTime.now().isBefore(deadline)) {
          if ((await fillAlpha(page) - alpha).abs() < 1e-3) return true;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        return false;
      }

      Future<void> waitForTier(
        pptr.Page page,
        String name, {
        Duration within = const Duration(seconds: 8),
      }) async {
        expect(
          await holds(page, "$_kTierAttribute === '$name'", within: within),
          isTrue,
          reason:
              'the document reached $name; it moved through '
              '${await reached(page)}',
        );
      }

      group('the tiers are a cascade the browser matches', () {
        test(
          'each tier takes away what the ladder says, and the top gives it '
          'back',
          () async {
            final page = await open(stated: {'forced': 'full'});
            await expectBentAtFull(page);
            final fullAlpha = await fillAlpha(page);
            expect(await filter(page), contains('blur('));
            expect(
              fullAlpha,
              lessThan(1),
              reason: 'the premise: the glass fill is translucent',
            );

            // Without the bend: the blur and the translucent fill stay.
            await state(page, {'forced': 'noRefraction'});
            await waitForTier(page, 'noRefraction');
            expect(
              await holds(page, '!($_kSurfaceBent)'),
              isTrue,
              reason: 'the host took the bend off the surface',
            );
            expect(await filter(page), contains('blur('));
            expect(await fillBecomes(page, fullAlpha), isTrue);
            expect(
              await page.evaluate<String>('() => couiQualityTier()'),
              'noRefraction',
              reason: 'and the scope published it',
            );

            // Without the backdrop pass: opaque, nothing to bend.
            await state(page, {'forced': 'solid'});
            await waitForTier(page, 'solid');
            expect(await filter(page), 'none');
            expect(await fillBecomes(page, 1), isTrue);
            expect(await bent(page), isFalse);

            // And the top gives all of it back.
            await state(page, {'forced': 'full'});
            await waitForTier(page, 'full');
            expect(
              await holds(page, _kSurfaceBent),
              isTrue,
              reason: 'the host bent the surface again',
            );
            expect(await filter(page), contains('blur('));
            expect(await fillBecomes(page, fullAlpha), isTrue);
            await page.close();
          },
          skip: noChrome,
        );

        test(
          'a step fades the fill like a theme change, and is instant for '
          'someone who asked for less motion',
          () async {
            final page = await open(stated: {'forced': 'full'});
            await expectBentAtFull(page);
            Future<String> fade() => page.evaluate<String>(
              "() => getComputedStyle(document.getElementById('s0')) "
              '.transitionDuration',
            );

            expect(
              await fade(),
              isNot(anyOf('0s', '0ms')),
              reason: 'the premise: the surface fades between two looks',
            );

            await page.devTools.emulation.setEmulatedMedia(
              features: [
                protocol.MediaFeature(
                  name: 'prefers-reduced-motion',
                  value: 'reduce',
                ),
              ],
            );
            expect(
              await holds(
                page,
                "getComputedStyle(document.getElementById('s0')) "
                ".transitionDuration === '0s'",
              ),
              isTrue,
              reason: 'the step has no motion left to reduce: it is instant',
            );
            await state(page, {'forced': 'solid'});
            await waitForTier(page, 'solid');
            expect(await fillBecomes(page, 1), isTrue);
            await page.close();
          },
          skip: noChrome,
        );

        test(
          'a tier the app starts at is where the first paint is',
          () async {
            final page = await open(stated: {'initial': 'noRefraction'});

            expect(await tier(page), 'noRefraction');
            // Settled: no bend was ever attached to take off.
            await Future<void>.delayed(const Duration(milliseconds: 600));
            expect(await bent(page), isFalse);
            expect(await filter(page), contains('blur('));
            await page.close();
          },
          skip: noChrome,
        );

        test(
          'an app that states nothing writes nothing and measures nothing',
          () async {
            final page = await open();
            await expectBentAtFull(page);

            expect(await tier(page), isNull);
            expect(
              await page.evaluate<String>('() => couiQualityTier()'),
              'full',
            );
            expect(
              await framesAsked(page, const Duration(seconds: 2)),
              0,
              reason: 'nothing asks a frame of an idle page that opted out',
            );
            await page.close();
          },
          skip: noChrome,
        );

        test(
          'an app that stops stating it gets the style in full again',
          () async {
            final page = await open(stated: {'forced': 'solid'});
            expect(await tier(page), 'solid');
            expect(await filter(page), 'none');

            await state(page, null);
            await waitForTier(page, 'full');
            expect(await filter(page), contains('blur('));
            expect(await holds(page, _kSurfaceBent), isTrue);
            await page.close();
          },
          skip: noChrome,
        );
      });

      group('the page is asked for frames only while it moves', () {
        test(
          'a real pointer wakes it, and the grace puts it back to sleep',
          () async {
            final page = await open(stated: _kMeasuring);
            await expectBentAtFull(page);

            // The page has just loaded, which is motion; the grace ends.
            await Future<void>.delayed(const Duration(seconds: 3));
            expect(
              await framesAsked(page, const Duration(milliseconds: 1500)),
              0,
              reason: 'an idle page is left idle',
            );

            await page.mouse.move(const Point(100, 100));
            await page.mouse.move(const Point(140, 120));
            final awake = await framesAsked(
              page,
              const Duration(milliseconds: 700),
            );
            expect(
              awake,
              greaterThan(10),
              reason: 'a pointer is a sign of motion: frames are asked for',
            );

            await Future<void>.delayed(const Duration(seconds: 2));
            expect(
              await framesAsked(page, const Duration(milliseconds: 1500)),
              0,
              reason: 'and it sleeps again once the grace has passed',
            );
            await page.close();
          },
          skip: noChrome,
        );

        test(
          'a long frame is a sign of motion too',
          () async {
            final page = await open(stated: _kMeasuring);
            if (!await page.evaluate<bool>(_kSupportsLoaf)) {
              markTestSkipped('this Chrome reports no long animation frames');
              await page.close();
              return;
            }
            await Future<void>.delayed(const Duration(seconds: 3));
            expect(
              await framesAsked(page, const Duration(milliseconds: 1000)),
              0,
              reason: 'the premise: the page is asleep',
            );

            await page.evaluate<void>(_kLongFrame);
            final before = await rafCalls(page);
            expect(
              await holds(page, 'window.__rafCalls > $before'),
              isTrue,
              reason: 'the browser said the page held a frame up: it moves',
            );
            await page.close();
          },
          skip: noChrome,
        );
      });

      group('the governor reads the page it is on', () {
        test(
          'steps down when the page cannot keep up, and takes the rungs back '
          'when it can',
          () async {
            if (unsteady != null) {
              markTestSkipped(unsteady!);
              return;
            }
            final page = await open(stated: _kMeasuring);
            await expectBentAtFull(page);
            await page.evaluate<void>('() => couiMoving(true)');

            // Comfortable: a few milliseconds of work a frame, unthrottled.
            await page.evaluate<void>('() => couiLoad(3)');
            await Future<void>.delayed(const Duration(seconds: 3));
            expect(
              await changes(page),
              isEmpty,
              reason: 'a page that keeps up keeps its glass',
            );
            expect(await tier(page), 'full');

            // The same page, a slower processor.
            await throttle(page, 8);
            await waitForTier(
              page,
              'solid',
              within: const Duration(seconds: 25),
            );
            final down = await changes(page);
            stdout.writeln('AQ-down $down');
            expect(
              [for (final c in down) c['to']],
              ['noRefraction', 'solid'],
              reason: "one rung at a time, in the ladder's order",
            );
            expect([
              for (final c in down) c['reason'],
            ], everyElement('overrun'));
            expect(await filter(page), 'none');
            expect(await fillBecomes(page, 1), isTrue);
            expect(await bent(page), isFalse);
            expect(
              await page.evaluate<String>('() => couiQualityTier()'),
              'solid',
            );

            // The slow processor is gone: the rungs come back, slowly.
            await throttle(page, 1);
            await page.evaluate<void>('() => couiLoad(0)');
            await waitForTier(
              page,
              'full',
              within: const Duration(seconds: 40),
            );
            final all = await changes(page);
            stdout.writeln('AQ-all $all');
            expect(
              [for (final c in all.skip(down.length)) c['to']],
              ['noRefraction', 'full'],
            );
            expect([
              for (final c in all.skip(down.length)) c['reason'],
            ], everyElement('headroom'));
            expect(
              await holds(page, _kSurfaceBent),
              isTrue,
              reason: 'the bend is back on the surface',
            );
            await page.close();
          },
          skip: noChrome,
          timeout: const Timeout(Duration(minutes: 3)),
        );

        test(
          'does not judge a page it was told is hidden, and starts over when '
          'it is shown',
          () async {
            if (unsteady != null) {
              markTestSkipped(unsteady!);
              return;
            }
            final page = await open(stated: _kMeasuring);
            await expectBentAtFull(page);
            await page.evaluate<void>('() => couiMoving(true)');
            await page.evaluate<void>('() => couiLoad(3)');
            await throttle(page, 8);
            await page.evaluate<void>(_kHide);
            final before = await rafCalls(page);

            await Future<void>.delayed(const Duration(seconds: 5));
            expect(
              await changes(page),
              isEmpty,
              reason: 'a hidden tab is throttled by the browser, not the glass',
            );
            expect(await tier(page), 'full');
            expect(
              await rafCalls(page) - before,
              lessThanOrEqualTo(1),
              reason: 'no loop runs while the tab is hidden',
            );

            await page.evaluate<void>(_kShow);
            await waitForTier(
              page,
              'solid',
              within: const Duration(seconds: 40),
            );
            await page.close();
          },
          skip: noChrome,
          timeout: const Timeout(Duration(minutes: 3)),
        );

        test(
          'does not judge the page while the app holds it, and does after',
          () async {
            if (unsteady != null) {
              markTestSkipped(unsteady!);
              return;
            }
            final page = await open(stated: _kMeasuring);
            await expectBentAtFull(page);
            await page.evaluate<void>('() => couiMoving(true)');
            await page.evaluate<void>('() => couiLoad(3)');
            await throttle(page, 8);
            expect(await page.evaluate<int>('() => couiQualityHold()'), 1);

            await Future<void>.delayed(const Duration(seconds: 5));
            expect(
              await changes(page),
              isEmpty,
              reason: 'heavy work of the app’s own is not the glass',
            );
            expect(await tier(page), 'full');

            expect(await page.evaluate<int>('() => couiQualityRelease()'), 0);
            await waitForTier(
              page,
              'solid',
              within: const Duration(seconds: 40),
            );
            await page.close();
          },
          skip: noChrome,
          timeout: const Timeout(Duration(minutes: 3)),
        );

        test(
          'stops listening when the app stops stating it',
          () async {
            if (unsteady != null) {
              markTestSkipped(unsteady!);
              return;
            }
            final page = await open(stated: _kMeasuring);
            await expectBentAtFull(page);
            await page.evaluate<void>('() => couiMoving(true)');
            await page.evaluate<void>('() => couiLoad(3)');

            await state(page, null);
            await waitForTier(page, 'full');
            await throttle(page, 8);

            // Motion goes on, the page is slow, and nothing answers it: not a
            // tier, not a frame asked for.
            await Future<void>.delayed(const Duration(seconds: 1));
            expect(
              await framesAsked(page, const Duration(seconds: 3)),
              0,
              reason: 'the listeners went with the statement',
            );
            expect(await tier(page), 'full');
            expect(await changes(page), isEmpty);
            await page.close();
          },
          skip: noChrome,
          timeout: const Timeout(Duration(minutes: 3)),
        );

        test(
          'a reduce-transparency preference outranks it: opaque at once, '
          'unmeasured, and measured again when it ends',
          () async {
            if (unsteady != null) {
              markTestSkipped(unsteady!);
              return;
            }
            final page = await open(stated: _kMeasuring);
            await expectBentAtFull(page);
            await page.evaluate<void>('() => couiMoving(true)');
            await page.evaluate<void>('() => couiLoad(3)');
            await throttle(page, 8);

            await page.devTools.emulation.setEmulatedMedia(
              features: [
                protocol.MediaFeature(
                  name: 'prefers-reduced-transparency',
                  value: 'reduce',
                ),
              ],
            );
            final honoured = await page.evaluate<bool>(
              "() => matchMedia('(prefers-reduced-transparency: reduce)') "
              '.matches',
            );
            if (!honoured) {
              markTestSkipped(
                'this Chrome does not honour an emulated reduce-transparency '
                'preference',
              );
              await page.close();
              return;
            }

            // The sheet's own answer to the preference, at the full tier —
            // and the scope says what the surfaces are: the lowest tier.
            expect(await filter(page), 'none');
            expect(await fillBecomes(page, 1), isTrue);
            expect(
              await holds(
                page,
                "couiQualityTier() === 'solid'",
              ),
              isTrue,
              reason: 'the scope publishes the tier the surfaces are drawn at',
            );

            await Future<void>.delayed(const Duration(seconds: 5));
            expect(
              await changes(page),
              isEmpty,
              reason: 'the surfaces are opaque already: nothing to judge',
            );
            expect(await tier(page), 'full');

            await page.devTools.emulation.setEmulatedMedia(
              features: [
                protocol.MediaFeature(
                  name: 'prefers-reduced-transparency',
                  value: 'no-preference',
                ),
              ],
            );
            expect(await filter(page), contains('blur('));
            expect(
              await holds(page, "couiQualityTier() === 'full'"),
              isTrue,
              reason: 'and the scope follows the preference back',
            );
            await waitForTier(
              page,
              'solid',
              within: const Duration(seconds: 40),
            );
            await page.close();
          },
          skip: noChrome,
          timeout: const Timeout(Duration(minutes: 3)),
        );
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

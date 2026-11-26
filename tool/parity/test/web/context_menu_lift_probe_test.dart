// The Web ContextMenu's lift of its source, driven by real input in Chrome.
//
// The VM can pin the touch tracker that times the hold, the lift's bookkeeping,
// the CSS the resolver gives for a progress and the markup
// (`packages/coui_web/test/components/menu/context_menu_lift_test.dart` replays
// the shared table on them with a manual clock). It cannot reach what makes the
// lift a lift in a browser: the source measured off layout, a copy promoted
// into the top layer *under* the panel, frames of a real
// `requestAnimationFrame`, a computed `transform` at a moment of a real touch,
// `inert` and `aria-hidden` on a picture, a panel folded by a keyframes
// animation about a point measured off the page, and a page that scrolls under
// the open menu. This file compiles the shipped component
// (`tool/parity/src/web/context_menu_lift_entry.dart`) and judges it in Chrome.
//
// ## What is replayed
//
// Every trace of the shared lift table the Web is named in
// (`context_menu_lift_vectors.json`) - the same traces the Core test replays on
// the functions, the Flutter test as pointer and key events, and the VM test on
// the tracker - as touch, mouse and key input through the DevTools input
// domain, in real time. The page records, on every frame, what the copy looks
// like (its computed scale, the dim's alpha, the cast) and whether the original
// is hidden; the events it saw are recorded with the page's own clock. Each
// frame is then compared with what Core says the lift looks like at *that*
// frame's time given the times the events actually happened - so Chrome's
// scheduling jitter does not matter and the lift's clock does.
//
// ## What else is judged here
//
// * the original is hidden exactly while the copy is up, in every frame;
// * the copy goes into the top layer before the panel does, so the panel lies
//   over it;
// * a pointer at the region reaches the original (the copy ignores it), and the
//   copy is `aria-hidden` and `inert` while the accessibility tree holds the
//   original once;
// * the child is built twice while the menu is open - the original keeps its
//   state, the copy starts from nothing - and once again after;
// * closing folds the panel (and the preview) toward the nearest point of the
//   source: the keyframes animation, paused at the table's fractions of the
//   close, is at the scale and opacity of the retract curve and at the rect
//   Core gives about the pivot, measured off the page;
// * the copy, the panel and the original come and go in the same frame, and
//   nothing is left behind;
// * a page that scrolls under the open menu takes the copy with it;
// * reduced motion: the lifted state arrives and leaves at once; forced
//   colours: the dim is left out;
// * an opening with no hold does not delay the menu;
// * a menu whose style states other numbers (`override` in the table) lifts,
//   rises over the rise it states (held to what the hold leaves), casts, dims
//   and folds with those numbers - the traces replayed again with the style
//   given to the page.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:path/path.dart' as p;
import 'package:puppeteer/protocol/emulation.dart' as cdp show MediaFeature;
import 'package:puppeteer/protocol/input.dart' show TouchPoint;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// The table shared with Core, Flutter and the VM Web tests (cwd is the
/// repository root under `dart test tool/parity/test`).
const String _kVectorsPath =
    'packages/coui_core/test/fixtures/context_menu_lift_vectors.json';

const String _kEntryPath = 'tool/parity/src/web/context_menu_lift_entry.dart';

/// A phone-sized viewport - the one a long press is for.
const int _kPhoneWidth = 390;
const int _kPhoneHeight = 640;

/// Where the region is in the document (the entry puts it there), and its size.
const double _kRegionLeft = 60;
const double _kRegionTop = 160;

/// One frame at 60 Hz, plus what a headless Chrome may add. A frame's DOM is
/// the result of the lift's frame some way before the recorder reads it.
const double _kLagMs = 24;

/// How much earlier than the frame before a lift's value may have been drawn:
/// the lift draws in the frame's own callback, which can run a few milliseconds
/// after the recorder's one, and the component's listeners run after the
/// window's capturing one that stamps the events the probe compares with.
/// Small beside the lift (300 ms) and the delay (150 ms), so a lift that
/// begins, ends or turns late or early by a frame still fails.
const double _kSlackMs = 4;

/// The step the probe samples the lift's model at over the window of a frame.
/// The model turns at a point (the release, the close): a step coarser than
/// the tolerances allow would step over the turn and call a value the page
/// really drew impossible. A tenth of a millisecond moves the lift by less than
/// the tolerances read (a hundredth of a pixel of blur, a hundred-thousandth of
/// the scale).
const double _kSampleStepMs = 0.1;

/// How far a computed length may be from the one written: Chrome writes a
/// computed `box-shadow` length with six significant digits.
const double _kLengthStep = 0.05;

/// How far a computed colour's alpha may be from the one written: Chrome keeps
/// it in 8 bits (1/255) and writes it in two digits (0.005 of rounding).
const double _kAlphaStep = 0.012;

/// What the page records from before its own scripts run: when the component
/// asked for each vibration, the events that reached the window with the
/// page's clock, every `showPopover()` (the order panels join the top layer in
/// is the order they lie in), and a count of frames.
const String _kSpyJs = '''
() => {
  const probe = window.__probe = {
    events: [], promotions: [], frames: 0, vibrations: [],
  };
  const show = HTMLElement.prototype.showPopover;
  HTMLElement.prototype.showPopover = function () {
    probe.promotions.push({id: this.id, t: performance.now()});
    return show.call(this);
  };
  Object.defineProperty(Navigator.prototype, 'vibrate', {
    configurable: true, writable: true,
    value() { probe.vibrations.push(performance.now()); return true; },
  });
  const note = (type) => (e) => {
    probe.events.push({type, t: performance.now(), key: e.key, x: e.clientX,
      y: e.clientY, button: e.button});
  };
  for (const type of ['pointerdown', 'pointermove', 'pointerup',
      'pointercancel', 'keydown', 'contextmenu']) {
    addEventListener(type, note(type), true);
  }
  addEventListener('scroll', note('scroll'), true);
  const tick = () => { probe.frames++; requestAnimationFrame(tick); };
  requestAnimationFrame(tick);
}
''';

/// Starts recording, on every frame, what the lift looks like: whether the
/// copy is in the document, its computed scale, the alpha of the dim, the
/// cast's first layer, and whether the original is hidden. Stopped by
/// `__stop()`.
const String _kRecordJs = r'''
() => {
  const rec = window.__rec = {frames: [], on: true};
  const alphaOf = (c) => {
    const m = /\/\s*([\d.]+)\)/.exec(c);
    if (m) return parseFloat(m[1]);
    if (c.startsWith('rgba')) return parseFloat(c.split(',').pop());
    return c.startsWith('rgb') ? 1 : 0;
  };
  const read = () => {
    if (!rec.on) return;
    const layer = document.querySelector('[id^="co-context-menu-lift"]');
    const source = document.querySelector('[id^="co-context-menu-source"]');
    const frame = {
      t: performance.now(),
      lift: !!layer,
      hidden: source ? getComputedStyle(source).opacity === '0' : null,
      panel: !!document.querySelector('[id^="co-context-menu-panel"]'),
    };
    if (layer) {
      const dim = layer.children[0];
      const copy = layer.children[1];
      frame.scale = new DOMMatrix(getComputedStyle(copy).transform).a;
      frame.dim = alphaOf(getComputedStyle(dim).backgroundColor);
      frame.shadow = getComputedStyle(copy).boxShadow;
      const r = copy.getBoundingClientRect();
      frame.copy = [r.left, r.top, r.right, r.bottom];
    }
    rec.frames.push(frame);
    requestAnimationFrame(read);
  };
  requestAnimationFrame(read);
  window.__stop = () => { rec.on = false; return JSON.stringify(rec.frames); };
}
''';

/// The geometry the probe compares with: the source's rect, the open panel's
/// and the preview's, as Chrome has them.
const String _kRectsJs = '''
() => {
  const box = (e) => {
    if (!e) return null;
    const r = e.getBoundingClientRect();
    return [r.left, r.top, r.right, r.bottom];
  };
  return JSON.stringify({
    source: box(document.querySelector('[id^="co-context-menu-source"]')),
    panel: box(document.querySelector('[id^="co-context-menu-panel"]')),
    motion: box(document.querySelector('[id^="co-context-menu-panel"] > div')),
    previewMotion: box(
      document.querySelector('[id^="co-context-menu-preview"] > div')),
    copy: (() => {
      const layer = document.querySelector('[id^="co-context-menu-lift"]');
      return layer ? box(layer.children[1]) : null;
    })(),
  });
}
''';

typedef _Frame = ({
  double t,
  bool lift,
  bool? hidden,
  bool panel,
  double? scale,
  double? dim,
  String? shadow,
  CoreMenuBox? copy,
});

typedef _Event = ({String type, double t, String? key, double? x, double? y});

CoreMenuBox? _box(Object? edges) {
  if (edges == null) return null;
  final e = (edges as List).cast<num>().map((v) => v.toDouble()).toList();

  return CoreMenuBox(left: e[0], top: e[1], right: e[2], bottom: e[3]);
}

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

double _num(Object? value) => (value! as num).toDouble();

String? _chromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in [
    if (Platform.environment['CHROME_EXECUTABLE'] case final String chrome
        when chrome.isNotEmpty)
      chrome,
    ...candidates,
  ]) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

Future<void> _frames(pptr.Page page, [int count = 2]) async {
  for (var i = 0; i < count; i++) {
    await page.evaluate<void>(
      '() => new Promise(resolve => requestAnimationFrame(() => resolve()))',
    );
  }
}

Future<void> _sleep(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

List<_Frame> _framesOf(String json) => [
  for (final f in _list(jsonDecode(json)))
    (
      t: _num(f['t']),
      lift: f['lift']! as bool,
      hidden: f['hidden'] as bool?,
      panel: f['panel']! as bool,
      scale: (f['scale'] as num?)?.toDouble(),
      dim: (f['dim'] as num?)?.toDouble(),
      shadow: f['shadow'] as String?,
      copy: _box(f['copy']),
    ),
];

Future<List<_Event>> _events(pptr.Page page) async {
  final json = await page.evaluate<String>(
    '() => JSON.stringify(window.__probe.events)',
  );

  return [
    for (final e in _list(jsonDecode(json)))
      (
        type: e['type']! as String,
        t: _num(e['t']),
        key: e['key'] as String?,
        x: (e['x'] as num?)?.toDouble(),
        y: (e['y'] as num?)?.toDouble(),
      ),
  ];
}

/// One finger, sent as touch events through the DevTools input domain.
class _Finger {
  _Finger(this.page);

  final pptr.Page page;

  Future<void> _send(String type, List<TouchPoint> points) =>
      page.devTools.input.dispatchTouchEvent(type, points);

  Future<void> down(double x, double y) =>
      _send('touchStart', [TouchPoint(x: x, y: y, id: 1)]);

  Future<void> move(double x, double y) =>
      _send('touchMove', [TouchPoint(x: x, y: y, id: 1)]);

  Future<void> up() => _send('touchEnd', const []);

  Future<void> cancel() => _send('touchCancel', const []);
}

/// What Core says the lift looks like at [t] ms on the page's clock, for an
/// opening that began at [began], was set down by a release at [released] (or
/// not), and was closed at [closed] over [closeMs] (or not).
///
/// The lift of a held touch rises after the delay; one with no hold rises at
/// once. Both are `CoreContextMenuLiftTimeline`, fed the calls a host makes.
double _expectedProgress(
  double t, {
  required double began,
  required bool held,
  double? released,
  double? committed,
  double? closed,
  int closeMs = 100,
  Duration rise = CoreContextMenuStyle.defaultLiftDuration,
}) {
  final timeline = CoreContextMenuLiftTimeline(duration: rise);
  Duration at(double ms) => Duration(microseconds: (ms * 1000).round());
  timeline.begin(at(began), held: held);
  if (committed != null && committed <= t) timeline.commit(at(committed));
  if (released != null && released <= t) timeline.release(at(released));
  if (closed != null && closed <= t) {
    timeline.close(at(closed), duration: Duration(milliseconds: closeMs));
  }

  return timeline.progress(at(t));
}

void main() {
  final chromePath = _chromePath();
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final numbers = doc['numbers']! as Map<String, Object?>;
  final restyled = doc['override']! as Map<String, Object?>;
  final holdMs = _num(numbers['holdMs']);
  final closeMs = (numbers['closeMs']! as num).toInt();
  final retractCurve = _list(doc['retractCurve']);

  late pptr.Browser browser;
  late Directory fixture;
  late File html;

  setUpAll(() async {
    if (chromePath == null) return;
    fixture = Directory.systemTemp.createTempSync('coui-ctx-lift-probe-');
    final js = p.join(fixture.path, 'entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O1',
      '-o',
      js,
      _kEntryPath,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    // Real motion: the lift, the fold and the panel's enter are what is judged.
    final content = buildOfflineTailwindHarnessHtml(
      bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>',
    ).replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
    html = File(p.join(fixture.path, 'index.html'))..writeAsStringSync(content);
    browser = await launchCaptureBrowser(
      width: _kPhoneWidth,
      height: _kPhoneHeight,
      executablePath: chromePath,
    );
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    fixture.deleteSync(recursive: true);
  });

  final skip = chromePath == null
      ? 'no local Chrome - the lift cannot be checked against a browser here'
      : null;

  Future<pptr.Page> openPage({List<String>? errors}) async {
    final page = await browser.newPage();
    await page.setViewport(
      const pptr.DeviceViewport(
        width: _kPhoneWidth,
        height: _kPhoneHeight,
        hasTouch: true,
      ),
    );
    await page.evaluateOnNewDocument(_kSpyJs);
    if (errors != null) {
      page.onError.listen((error) => errors.add('$error'));
    }
    await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
    await page.waitForFunction('typeof couiLiftConfigure === "function"');

    return page;
  }

  Future<void> configure(
    pptr.Page page, {
    bool lift = true,
    bool haptics = false,
    bool glide = false,
    int rows = 3,
    int? closeMs,
    Map<String, Object?>? preview,
    Map<String, Object?>? style,
  }) async {
    await page.evaluate<void>(
      '(c) => couiLiftConfigure(c)',
      args: [
        jsonEncode({
          'lift': lift,
          'haptics': haptics,
          'glide': glide,
          'rows': rows,
          'closeMs': ?closeMs,
          'preview': ?preview,
          'style': ?style,
        }),
      ],
    );
    await _frames(page, 4);
  }

  Future<void> startRecording(pptr.Page page) async {
    await page.evaluate<void>(_kRecordJs);
    await _frames(page);
  }

  Future<List<_Frame>> stopRecording(pptr.Page page) async =>
      _framesOf(await page.evaluate<String>('() => window.__stop()'));

  Future<bool> panelOpen(pptr.Page page) => page.evaluate<bool>(
    '() => !!document.querySelector(\'#coui-overlay-menu [role="menu"]\')',
  );

  Future<void> waitClosed(pptr.Page page) => page.waitForFunction(
    '''
() => !document.querySelector('[id^="co-context-menu-panel"]')
        && !document.querySelector('[id^="co-context-menu-lift"]')''',
    timeout: const Duration(seconds: 20),
  );

  /// Everything the page should have put away once a menu is closed.
  Future<void> expectPutAway(pptr.Page page, {String reason = ''}) async {
    await waitClosed(page);
    await _frames(page, 3);
    final left = await page.evaluate<String>('''
() => JSON.stringify({
      layers: document.querySelectorAll('[id^="co-context-menu-lift"]').length,
      panels: document.querySelectorAll('[data-coui-overlay-panel]').length,
      popovers: document.querySelectorAll(':popover-open').length,
      hidden: getComputedStyle(
        document.querySelector('[id^="co-context-menu-source"]')).opacity,
      counters: document.querySelectorAll('.counter').length,
    })''');
    final read = jsonDecode(left) as Map<String, Object?>;
    expect(read['layers'], 0, reason: '$reason: no copy left');
    expect(read['panels'], 0, reason: '$reason: no panel left');
    expect(
      read['popovers'],
      0,
      reason: '$reason: nothing left in the top layer',
    );
    expect(read['hidden'], '1', reason: '$reason: the original is shown');
    expect(read['counters'], 1, reason: '$reason: the child is built once');
  }

  /// Checks every recorded frame against what Core says the lift looks like at
  /// that frame's time. A frame's DOM is the result of the lift's frame some
  /// way before it is read (the lift redraws in the frame; the recorder reads
  /// in the same one), so the value read must be one the lift has at some
  /// moment of the last [_kLagMs] ms.
  void expectFrames(
    List<_Frame> frames,
    double Function(double t) progressAt, {
    required String reason,
    double liftScale = CoreContextMenuStyle.defaultLiftScale,
    double dimOpacity = CoreContextMenuStyle.defaultLiftDimOpacity,
    List<CoreShadowLayer> cast = CoreContextMenuStyle.defaultLiftCast,
  }) {
    var sawLift = false;
    for (var index = 0; index < frames.length; index++) {
      final frame = frames[index];
      // The recorder may read before the lift has drawn in the same frame, so
      // what it reads is what the lift drew at some moment since the frame
      // before - a frame that came late (the page was busy: a long task while
      // a panel mounts) widens its own window and no other.
      final since = index == 0
          ? frame.t - _kLagMs
          : frames[index - 1].t - _kSlackMs;
      // Hidden exactly while the copy is up.
      if (frame.hidden != null) {
        expect(
          frame.hidden,
          frame.lift,
          reason:
              '$reason at ${frame.t.toStringAsFixed(0)}: the original is '
              'hidden exactly while the copy is up',
        );
      }
      // The values the lift has over the window the frame may come from.
      final lowest = <double>[];
      for (var t = since; t <= frame.t + 2; t += _kSampleStepMs) {
        lowest.add(progressAt(t));
      }
      final minProgress = lowest.reduce(math.min);
      final maxProgress = lowest.reduce(math.max);

      if (!frame.lift) {
        // No copy: the lift is, at some moment of the window, not yet up or
        // already put away.
        expect(
          minProgress,
          lessThan(0.02),
          reason:
              '$reason at ${frame.t.toStringAsFixed(0)}: no copy drawn, '
              'but the lift is at $minProgress',
        );
        continue;
      }
      sawLift = true;
      final scaleLow = CoreContextMenuLift.scale(
        minProgress,
        liftScale: liftScale,
      );
      final scaleHigh = CoreContextMenuLift.scale(
        maxProgress,
        liftScale: liftScale,
      );
      expect(
        frame.scale,
        inInclusiveRange(scaleLow - 1e-4, scaleHigh + 1e-4),
        reason:
            '$reason at ${frame.t.toStringAsFixed(0)}: scale of the copy '
            "must be the lift's some moment in the last frame",
      );
      // A computed colour carries its alpha in 8 bits, written in two digits:
      // a step is 1/255 and the rounding is 0.005.
      expect(
        frame.dim,
        inInclusiveRange(
          CoreContextMenuLift.dim(minProgress, opacity: dimOpacity) -
              _kAlphaStep,
          CoreContextMenuLift.dim(maxProgress, opacity: dimOpacity) +
              _kAlphaStep,
        ),
        reason: '$reason at ${frame.t.toStringAsFixed(0)}: dim over the page',
      );
      // The cast: the first layer's offset and blur, in px as computed.
      final lengths = RegExp(r'(-?[\d.]+(?:e-?\d+)?)px')
          .allMatches(frame.shadow!)
          .map((m) => double.parse(m.group(1)!))
          .toList();
      final layer = cast.first;
      expect(lengths, hasLength(greaterThanOrEqualTo(4)), reason: frame.shadow);
      expect(
        lengths[1],
        inInclusiveRange(
          layer.offsetY * minProgress - _kLengthStep,
          layer.offsetY * maxProgress + _kLengthStep,
        ),
        reason: '$reason at ${frame.t.toStringAsFixed(0)}: cast offset',
      );
      expect(
        lengths[2],
        inInclusiveRange(
          layer.blurRadius * minProgress - _kLengthStep,
          layer.blurRadius * maxProgress + _kLengthStep,
        ),
        reason: '$reason at ${frame.t.toStringAsFixed(0)}: cast blur',
      );
    }
    final expectedUp = frames.any((f) => progressAt(f.t) > 0.05);
    expect(
      sawLift,
      expectedUp,
      reason: '$reason: the lift is seen exactly when there was one to see',
    );
  }

  // --- what the table does not say ---------------------------------------

  /// Opens the menu with a right click on the region.
  Future<void> rightClick(pptr.Page page) => page.mouse.click(
    const math.Point(_kRegionLeft + 60, _kRegionTop + 50),
    button: pptr.MouseButton.right,
  );

  Future<Map<String, Object?>> rects(pptr.Page page) async =>
      jsonDecode(await page.evaluate<String>(_kRectsJs))
          as Map<String, Object?>;

  Future<List<Map<String, Object?>>> promotions(pptr.Page page) async => _list(
    jsonDecode(
      await page.evaluate<String>(
        '() => JSON.stringify(window.__probe.promotions)',
      ),
    ),
  );

  group('on the page', () {
    test(
      'the copy joins the top layer before the panel, '
      'so the panel lies over it',
      skip: skip,
      () async {
        for (final open in <(String, Future<void> Function(pptr.Page))>[
          ('a right click', rightClick),
          (
            'a hold',
            (page) async {
              await _Finger(page).down(_kRegionLeft + 60, _kRegionTop + 50);
              await _sleep(800);
            },
          ),
        ]) {
          final page = await openPage();
          addTearDown(page.close);
          await configure(page, closeMs: closeMs);
          await open.$2(page);
          await _sleep(500);

          final ids = [
            for (final e in await promotions(page)) e['id']! as String,
          ];
          final lift = ids.indexWhere(
            (id) => id.startsWith('co-context-menu-lift'),
          );
          final panel = ids.indexWhere(
            (id) => id.startsWith('co-context-menu-panel'),
          );
          expect(lift, greaterThanOrEqualTo(0), reason: '${open.$1}: $ids');
          expect(panel, greaterThan(lift), reason: '${open.$1}: $ids');
        }
      },
    );

    test(
      'an opening with no hold lifts without delaying the menu',
      skip: skip,
      () async {
        Future<double> panelDelay({required bool lift}) async {
          final page = await openPage();
          addTearDown(page.close);
          await configure(page, lift: lift, closeMs: closeMs);
          await rightClick(page);
          await _sleep(600);
          final events = await _events(page);
          final clicked = events.firstWhere((e) => e.type == 'contextmenu').t;
          final panel = (await promotions(page)).firstWhere(
            (e) => (e['id']! as String).startsWith('co-context-menu-panel'),
          );

          return _num(panel['t']) - clicked;
        }

        final without = await panelDelay(lift: false);
        final withLift = await panelDelay(lift: true);

        expect(
          withLift - without,
          lessThan(34),
          reason:
              'the menu is up $withLift ms after the click with the lift and '
              '$without ms without it',
        );
      },
    );

    test(
      "the copy is a picture: out of the pointer's way, inert and unannounced",
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, closeMs: closeMs);
        await _Finger(page).down(_kRegionLeft + 60, _kRegionTop + 50);
        await _sleep(350);

        final read =
            jsonDecode(
                  await page.evaluate<String>('''
() => {
        const layer = document.querySelector('[id^="co-context-menu-lift"]');
        const source = document.querySelector('[id^="co-context-menu-source"]');
        const at = document.elementFromPoint($_kRegionLeft + 60, $_kRegionTop + 50);
        return JSON.stringify({
          layer: !!layer,
          ariaHidden: layer && layer.getAttribute('aria-hidden'),
          inert: layer && layer.inert,
          pointer: layer && getComputedStyle(layer).pointerEvents,
          hitIsOriginal: !!at && source.contains(at) && !layer.contains(at),
          sourceInert: source.inert,
          sourceAria: source.getAttribute('aria-hidden'),
          sourceOpacity: getComputedStyle(source).opacity,
          sourceDisplay: getComputedStyle(source).display,
        });
      }'''),
                )
                as Map<String, Object?>;

        expect(read['layer'], isTrue);
        expect(read['ariaHidden'], 'true');
        expect(read['inert'], isTrue);
        expect(read['pointer'], 'none');
        expect(
          read['hitIsOriginal'],
          isTrue,
          reason: 'a pointer reaches the original',
        );
        expect(read['sourceInert'], isFalse);
        expect(read['sourceAria'], isNull);
        expect(
          read['sourceOpacity'],
          '0',
          reason: 'hidden, but in the accessibility tree',
        );
        expect(read['sourceDisplay'], 'block');

        // The accessibility tree holds the original's text once.
        final snapshot = await page.accessibility.snapshot();
        var holders = 0;
        void walk(pptr.AXNode? node) {
          if (node == null) return;
          if (node.name == 'Hold me') holders++;
          node.children.forEach(walk);
        }

        walk(snapshot);
        expect(holders, 1, reason: 'the original is read, the copy is not');
        await _Finger(page).cancel();
      },
    );

    test(
      'the child is built twice while the menu is open: '
      'the original keeps its state',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, closeMs: closeMs);
        for (var i = 0; i < 3; i++) {
          await page.evaluate<void>('() => couiLiftIncrement()');
        }
        await _frames(page, 3);
        Future<Map<String, Object?>> counters() async =>
            jsonDecode(
                  await page.evaluate<String>('''
() => JSON.stringify({
            original: [...document.querySelectorAll(
              '[id^="co-context-menu-source"] .counter')].map((e) => e.textContent),
            copy: [...document.querySelectorAll(
              '[id^="co-context-menu-lift"] .counter')].map((e) => e.textContent),
          })'''),
                )
                as Map<String, Object?>;

        expect((await counters())['original'], ['count 3']);
        expect(
          (await counters())['copy'],
          isEmpty,
          reason: 'built once at rest',
        );

        await rightClick(page);
        await _sleep(500);
        final open = await counters();
        expect(open['original'], [
          'count 3',
        ], reason: 'the original kept its state');
        expect(open['copy'], [
          'count 0',
        ], reason: 'the copy has none of its own');

        await page.keyboard.press(pptr.Key.escape);
        await expectPutAway(page);
        final after = await counters();
        expect(after['original'], [
          'count 3',
        ], reason: 'it survived open and retract');
        expect(after['copy'], isEmpty);
      },
    );

    test(
      'closing folds the panel and the preview toward the nearest point of '
      'the source',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        const longClose = 2000;
        await configure(
          page,
          closeMs: longClose,
          preview: {'width': 120, 'height': 80},
        );
        await rightClick(page);
        await _sleep(700);
        final rest = await rects(page);
        final source = _box(rest['source'])!;
        // The boxes the folds are applied to: the animated boxes themselves,
        // at rest.
        final panel = _box(rest['motion'])!;
        final preview = _box(rest['previewMotion']);
        expect(preview, isNotNull, reason: 'the preview is up');

        await page.keyboard.press(pptr.Key.escape);
        await _sleep(80);

        // Pause the folds and read them at the table's fractions of the close.
        for (final row in retractCurve) {
          final fraction = _num(row['fraction']);
          final read =
              jsonDecode(
                    await page.evaluate<String>(
                      '''
(f) => {
          const folds = document.getAnimations().filter(
            (a) => a.animationName === 'co-overlay-retract');
          const out = {};
          for (const a of folds) {
            a.pause();
            a.currentTime = f * $longClose;
            const target = a.effect.target;
            const owner = target.closest('[id^="co-context-menu-panel"]')
              ? 'panel' : 'preview';
            const r = target.getBoundingClientRect();
            const cs = getComputedStyle(target);
            out[owner] = {
              box: [r.left, r.top, r.right, r.bottom],
              opacity: parseFloat(cs.opacity),
              scale: new DOMMatrix(cs.transform).a,
            };
          }
          return JSON.stringify(out);
        }''',
                      args: [fraction],
                    ),
                  )
                  as Map<String, Object?>;
          final frame = CoreContextMenuRetract.frame(
            fraction: fraction,
            panel: panel,
            source: source,
            endScale: CoreContextMenuStyle.defaultRetractScale,
          );
          final where = 'at ${(fraction * 100).round()}% of the close';
          for (final (owner, box) in [
            ('panel', panel),
            ('preview', preview!),
          ]) {
            final fold = read[owner]! as Map<String, Object?>;
            expect(
              _num(fold['scale']),
              closeTo(frame.scale, 1e-3),
              reason: '$owner scale $where',
            );
            expect(
              _num(fold['opacity']),
              closeTo(frame.opacity, 1e-3),
              reason: '$owner opacity $where',
            );
            final want = frame.applyTo(box);
            final got = _box(fold['box'])!;
            expect(
              got.left,
              closeTo(want.left, 0.6),
              reason: '$owner left $where',
            );
            expect(
              got.top,
              closeTo(want.top, 0.6),
              reason: '$owner top $where',
            );
            expect(
              got.right,
              closeTo(want.right, 0.6),
              reason: '$owner right $where',
            );
            expect(
              got.bottom,
              closeTo(want.bottom, 0.6),
              reason: '$owner bottom $where',
            );
          }
        }
      },
    );

    test(
      'the copy, the panel and the original come and go in the same frame',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, closeMs: 150);
        await rightClick(page);
        await _sleep(600);
        await page.evaluate<void>('''
() => {
        const seen = window.__gone = [];
        const note = (what) => seen.push({what, frame: window.__probe.frames});
        new MutationObserver((records) => {
          for (const r of records) {
            for (const n of r.removedNodes) {
              if (n.nodeType !== 1) continue;
              if (n.id && n.id.startsWith('co-context-menu-lift')) note('lift');
              if (n.id && n.id.startsWith('co-context-menu-panel')) note('panel');
              if (n.querySelector && n.querySelector('[id^="co-context-menu-panel"]')) note('panel');
            }
            if (r.type === 'attributes' && r.target.id
                && r.target.id.startsWith('co-context-menu-source')
                && !r.target.classList.contains('opacity-0')) note('original');
          }
        }).observe(document.documentElement, {
          childList: true, subtree: true, attributes: true,
          attributeFilter: ['class'],
        });
      }''');
        await page.keyboard.press(pptr.Key.escape);
        await waitClosed(page);
        await _frames(page, 3);

        final gone = _list(
          jsonDecode(
            await page.evaluate<String>(
              '() => JSON.stringify(window.__gone)',
            ),
          ),
        );
        final whats = {for (final g in gone) g['what']! as String};
        expect(
          whats,
          containsAll(['lift', 'panel', 'original']),
          reason: '$gone',
        );
        expect(
          {for (final g in gone) g['frame']! as int},
          hasLength(1),
          reason: 'one frame, never one without the others: $gone',
        );
      },
    );

    test(
      'a page that scrolls under the open menu takes the copy with it',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, closeMs: closeMs);
        await rightClick(page);
        await _sleep(500);
        final before = await rects(page);

        await page.evaluate<void>('() => window.scrollBy(0, 40)');
        await _frames(page, 4);
        final after = await rects(page);
        final source = _box(after['source'])!;
        final copy = _box(after['copy'])!;

        expect(
          source.top,
          closeTo(_box(before['source'])!.top - 40, 0.6),
          reason: 'the page scrolled',
        );
        expect(
          (copy.left + copy.right) / 2,
          closeTo((source.left + source.right) / 2, 0.6),
        );
        expect(
          (copy.top + copy.bottom) / 2,
          closeTo((source.top + source.bottom) / 2, 0.6),
          reason: 'the copy follows the original through the scroll',
        );
        await page.keyboard.press(pptr.Key.escape);
        await expectPutAway(page);
      },
    );

    test(
      'reduced motion: the lifted state arrives and leaves at once',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await page.emulateMediaFeatures([
          pptr.MediaFeature.prefersReducedMotion('reduce'),
        ]);
        await configure(page, closeMs: closeMs);
        await startRecording(page);
        final finger = _Finger(page);
        await finger.down(_kRegionLeft + 60, _kRegionTop + 50);
        await _sleep(300);
        await finger.up();
        await _sleep(300);
        final frames = await stopRecording(page);

        final lifted = frames.where((f) => f.lift).toList();
        expect(lifted, isNotEmpty, reason: 'the lifted state is shown');
        expect(
          lifted.first.scale,
          closeTo(CoreContextMenuStyle.defaultLiftScale, 2e-3),
          reason: 'and it arrives at its full size, not on the way there',
        );
        // After the release the copy is gone within a frame or two.
        final lastLift = frames.lastIndexWhere((f) => f.lift);
        expect(lastLift, lessThan(frames.length - 1));
        expect(
          lifted.length * 16.7,
          lessThan(300),
          reason: 'it stayed only while held',
        );
        await expectPutAway(page);
      },
    );

    test(
      'forced colours leave the dim out and keep the copy',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        // The page-level API names two media features; forced colours is
        // asked of the protocol directly.
        await page.devTools.emulation.setEmulatedMedia(
          features: [cdp.MediaFeature(name: 'forced-colors', value: 'active')],
        );
        await configure(page, closeMs: closeMs);
        await _Finger(page).down(_kRegionLeft + 60, _kRegionTop + 50);
        await _sleep(400);

        final read =
            jsonDecode(
                  await page.evaluate<String>('''
() => {
        const layer = document.querySelector('[id^="co-context-menu-lift"]');
        return JSON.stringify({
          dim: getComputedStyle(layer.children[0]).display,
          copy: getComputedStyle(layer.children[1]).display,
        });
      }'''),
                )
                as Map<String, Object?>;
        expect(read['dim'], 'none');
        expect(read['copy'], isNot('none'));
        await _Finger(page).cancel();
      },
    );

    test(
      'haptics: one tick as the hold commits, none for the other openings',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, haptics: true, closeMs: closeMs);
        // When the component asked for each vibration, on the page's clock.
        Future<List<double>> ticks() async =>
            (jsonDecode(
                      await page.evaluate<String>(
                        '() => JSON.stringify(window.__probe.vibrations)',
                      ),
                    )
                    as List)
                .map(_num)
                .toList();

        final finger = _Finger(page);
        await finger.down(_kRegionLeft + 60, _kRegionTop + 50);
        // Judged on the page's own clock, not by when the probe looks: a busy
        // machine can make the probe late, and the hold is up whenever it is.
        await page.waitForFunction(
          '() => window.__probe.vibrations.length > 0',
          timeout: const Duration(seconds: 20),
        );
        final touchedAt = (await _events(
          page,
        )).firstWhere((e) => e.type == 'pointerdown' && e.y != null).t;
        final tick = (await ticks()).single;
        expect(
          tick - touchedAt,
          // A timer may fire a hair before the clock it is read against says
          // the time is up.
          greaterThanOrEqualTo(holdMs - 2),
          reason: 'nothing before the hold is up',
        );
        await _sleep(300);
        expect(await ticks(), hasLength(1), reason: 'one as the hold commits');
        await finger.up();
        await page.keyboard.press(pptr.Key.escape);
        await expectPutAway(page);

        await rightClick(page);
        await _sleep(500);
        expect(
          await ticks(),
          hasLength(1),
          reason: 'a right click has no hold to pay off',
        );
        await page.keyboard.press(pptr.Key.escape);
        await expectPutAway(page);
      },
    );

    test(
      'the copy is drawn from frame to frame without building its child again',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, closeMs: closeMs);
        Future<({List<int> builds, int created})> counters() async {
          final read =
              jsonDecode(
                    await page.evaluate<String>('() => couiLiftBuilds()'),
                  )
                  as Map<String, Object?>;

          return (
            builds: (read['builds']! as List).cast<int>(),
            created: read['created']! as int,
          );
        }

        final atRest = await counters();
        expect(atRest.builds, [1], reason: 'one build at rest');
        await startRecording(page);
        await rightClick(page);
        await _sleep(600);
        final frames = await stopRecording(page);
        final lifting = frames.where((f) => f.lift).length;
        expect(lifting, greaterThan(8), reason: 'it was drawn on many frames');
        final lifted = await counters();
        expect(lifted.builds, [1, 1], reason: 'each built once, not per frame');
        expect(
          lifted.created - atRest.created,
          1,
          reason: 'one copy for the whole lift - never a copy built afresh',
        );

        await page.keyboard.press(pptr.Key.escape);
        await waitClosed(page);
        expect(
          (await counters()).builds,
          [1],
          reason: 'the copy is gone, the original untouched',
        );
      },
    );

    test(
      'turning the option off with a lift up takes the copy and the wrapper '
      'away at once',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, closeMs: closeMs);
        await rightClick(page);
        await _sleep(500);
        Future<Map<String, Object?>> read() async =>
            jsonDecode(
                  await page.evaluate<String>('''
() => JSON.stringify({
  layers: document.querySelectorAll('[id^="co-context-menu-lift"]').length,
  wrappers: document.querySelectorAll('[id^="co-context-menu-source"]').length,
  counters: document.querySelectorAll('.counter').length,
  panel: !!document.querySelector('[id^="co-context-menu-panel"]'),
  popovers: document.querySelectorAll(':popover-open').length,
})'''),
                )
                as Map<String, Object?>;

        final lifted = await read();
        expect(lifted['layers'], 1, reason: 'lifted');
        expect(lifted['counters'], 2, reason: 'the original and its copy');

        // The same menu, rendered again with the option off.
        await configure(page, lift: false, closeMs: closeMs);
        final off = await read();
        expect(off['layers'], 0, reason: 'the copy is gone');
        expect(
          off['wrappers'],
          0,
          reason: 'so is the wrapper around the child',
        );
        expect(off['counters'], 1, reason: 'the child shows once');
        expect(off['panel'], isTrue, reason: 'the menu stays open');

        // And it closes as a menu without the option does.
        await page.keyboard.press(pptr.Key.escape);
        await page.waitForFunction(
          '''
() => !document.querySelector('[id^="co-context-menu-panel"]')''',
          timeout: const Duration(seconds: 20),
        );
        await _frames(page, 3);
        final closed = await read();
        expect(closed['layers'], 0);
        expect(closed['popovers'], 0, reason: 'nothing left in the top layer');
        expect(closed['counters'], 1);
      },
    );

    test(
      'a child that does not lift is built once and not wrapped',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, lift: false, closeMs: closeMs);
        await rightClick(page);
        await _sleep(500);

        final read =
            jsonDecode(
                  await page.evaluate<String>('''
() => JSON.stringify({
        wrapper: document.querySelectorAll('[id^="co-context-menu-source"]').length,
        layer: document.querySelectorAll('[id^="co-context-menu-lift"]').length,
        counters: document.querySelectorAll('.counter').length,
        hasRetract: document.getAnimations().some(
          (a) => a.animationName === 'co-overlay-retract'),
      })'''),
                )
                as Map<String, Object?>;
        expect(read['wrapper'], 0);
        expect(read['layer'], 0);
        expect(read['counters'], 1);
        await page.keyboard.press(pptr.Key.escape);
        await _sleep(30);
        expect(
          await page.evaluate<bool>('''
() => document.getAnimations().some(
  (a) => a.animationName === 'co-overlay-retract')'''),
          isFalse,
          reason: 'it leaves with the ordinary exit',
        );
      },
    );
  });

  // --- the table, replayed with real input --------------------------------

  /// Replays [trace] on a page whose menu states [style] (absent: nothing),
  /// and judges every recorded frame against what Core says the lift looks
  /// like given the rise and the look the style states.
  Future<void> replayTrace(
    Map<String, Object?> trace, {
    Map<String, Object?>? style,
    Duration rise = CoreContextMenuStyle.defaultLiftDuration,
    double liftScale = CoreContextMenuStyle.defaultLiftScale,
    double dimOpacity = CoreContextMenuStyle.defaultLiftDimOpacity,
    List<CoreShadowLayer> cast = CoreContextMenuStyle.defaultLiftCast,
  }) async {
    final errors = <String>[];
    final page = await openPage(errors: errors);
    addTearDown(page.close);
    await configure(page, closeMs: closeMs, style: style);
    final finger = _Finger(page);
    final events = _list(trace['events']);
    final held = trace['held'] == true;

    // What the page clock said when the controller was used (the one input
    // the page's own listeners do not see).
    double? openedAt;
    double? closedAt;

    await startRecording(page);
    final start = Stopwatch()..start();
    for (final event in events) {
      final wait = (event['at']! as int) - start.elapsedMilliseconds;
      if (wait > 0) await _sleep(wait);
      switch (event['kind']! as String) {
        case 'down':
          await finger.down(
            _kRegionLeft + _num(event['x']),
            _kRegionTop + _num(event['y']),
          );
        case 'move':
          await finger.move(
            _kRegionLeft + _num(event['x']),
            _kRegionTop + _num(event['y']),
          );
        case 'up':
          await finger.up();
        case 'cancel':
          await finger.cancel();
        case 'scroll':
          await page.evaluate<void>('() => window.scrollBy(0, 30)');
        case 'open':
          switch (event['via']! as String) {
            case 'secondaryClick':
              await page.mouse.click(
                math.Point(
                  _kRegionLeft + _num(event['x']),
                  _kRegionTop + _num(event['y']),
                ),
                button: pptr.MouseButton.right,
              );
            case 'key':
              // The menu key and Shift+F10 reach a page as a `contextmenu`
              // event with no position (both coordinates 0) on Windows
              // and Linux, and not at all on macOS, where this runs - so
              // the event is sent the way a browser sends it.
              await page.evaluate<void>('''
() => {
                const region = document.querySelector('.lift-region');
                region.focus();
                region.dispatchEvent(new MouseEvent('contextmenu', {
                  bubbles: true, cancelable: true, clientX: 0, clientY: 0,
                }));
              }''');
            case 'controller':
              openedAt = _num(
                await page.evaluate<num>(
                  '() => { couiLiftOpen(); return performance.now(); }',
                ),
              );
            case final via:
              fail(
                'the table opened a menu in a way the probe cannot: $via',
              );
          }
        case 'close':
          switch (event['via']! as String) {
            case 'escape':
              await page.keyboard.press(pptr.Key.escape);
            case 'outside':
              await page.mouse.click(const math.Point(6, 6));
            case 'controller':
              closedAt = _num(
                await page.evaluate<num>(
                  '() => { couiLiftClose(); return performance.now(); }',
                ),
              );
            case final via:
              fail(
                'the table closed a menu in a way the probe cannot: $via',
              );
          }
        case final kind:
          fail('the table gave the probe an event it cannot replay: $kind');
      }
    }
    // Let everything finish: the menu leaves, the lift settles.
    await _sleep(closeMs + 500);
    if (await panelOpen(page)) {
      await page.keyboard.press(pptr.Key.escape);
      await _sleep(closeMs + 500);
    }
    final frames = await stopRecording(page);
    final seen = await _events(page);
    expect(errors, isEmpty);

    // When things happened, on the page's clock.
    double? firstOf(bool Function(_Event e) test) =>
        seen.where(test).map((e) => e.t).firstOrNull;
    final began =
        openedAt ??
        firstOf((e) => e.type == 'pointerdown' && e.y != null) ??
        firstOf((e) => e.type == 'contextmenu')!;
    // The press ends when the pointer lifts or is taken, when something
    // scrolls, or when it drifts past the slop it went down in.
    final downAt = seen.where(
      (e) => e.type == 'pointerdown' && e.y != null,
    );
    final pressEnd = downAt.isEmpty
        ? null
        : firstOf(
            (e) =>
                e.t > began &&
                (e.type == 'pointerup' ||
                    e.type == 'pointercancel' ||
                    e.type == 'scroll' ||
                    (e.type == 'pointermove' &&
                        e.x != null &&
                        e.y != null &&
                        CoreContextMenuContract.exceedsLongPressSlop(
                          originX: downAt.first.x!,
                          originY: downAt.first.y!,
                          x: e.x!,
                          y: e.y!,
                        ))),
          );
    // A press that ended before the hold was up never opened the menu.
    final paidOff = !held || pressEnd == null || pressEnd - began >= holdMs;
    final closed =
        closedAt ??
        firstOf((e) => e.type == 'keydown' && e.key == 'Escape') ??
        (events.any((e) => e['via'] == 'outside')
            ? seen
                  .where((e) => e.type == 'pointerdown' && e.t > began)
                  .map((e) => e.t)
                  .lastOrNull
            : null);

    expectFrames(
      frames,
      (t) => _expectedProgress(
        t,
        began: began,
        held: held,
        committed: paidOff ? began + (held ? holdMs : 0) : null,
        released: paidOff ? null : pressEnd,
        closed: closed,
        closeMs: closeMs,
        rise: rise,
      ),
      reason: '${trace['name']}',
      liftScale: liftScale,
      dimOpacity: dimOpacity,
      cast: cast,
    );
    await expectPutAway(page, reason: '${trace['name']}');
  }

  group('every trace of the shared table the Web is named in', () {
    final traces = _list(doc['traces']);

    for (final trace in traces) {
      final platforms = (trace['platforms'] as List?)?.cast<String>();
      if (platforms != null && !platforms.contains('web')) continue;

      test('${trace['name']}', skip: skip, () => replayTrace(trace));
    }
  });

  group('a style that states other numbers, every trace of the table', () {
    final other = restyled['numbers']! as Map<String, Object?>;

    /// The style as the page API takes it: the numbers of the `override`
    /// block, with the rise a trace names.
    Map<String, Object?> styleJson(int liftMs) => {
      'liftScale': other['liftScale'],
      'liftMs': liftMs,
      'dim': other['dimOpacity'],
      'radius': other['radius'],
      'retractScale': other['retractScale'],
      'cast': other['cast'],
    };

    List<CoreShadowLayer> castOf() => [
      for (final layer in _list(other['cast']))
        (
          offsetX: _num(layer['offsetX']),
          offsetY: _num(layer['offsetY']),
          blurRadius: _num(layer['blurRadius']),
          spreadRadius: _num(layer['spreadRadius']),
          opacity: _num(layer['opacity']),
          inset: false,
        ),
    ];

    for (final trace in _list(restyled['traces'])) {
      final platforms = (trace['platforms'] as List?)?.cast<String>();
      if (platforms != null && !platforms.contains('web')) continue;
      final liftMs = (trace['durationMs']! as num).toInt();

      test('${trace['name']}', skip: skip, () {
        return replayTrace(
          trace,
          style: styleJson(liftMs),
          rise: Duration(milliseconds: liftMs),
          liftScale: _num(other['liftScale']),
          dimOpacity: _num(other['dimOpacity']),
          cast: castOf(),
        );
      });
    }

    test(
      'the cast box has the corners the style states',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        await configure(page, closeMs: closeMs, style: styleJson(200));
        await rightClick(page);
        await _sleep(700);

        final corner = await page.evaluate<String>('''
() => getComputedStyle(
          document.querySelector('[id^="co-context-menu-lift"]').children[1],
        ).borderTopLeftRadius''');
        expect(
          corner,
          '${_num(other['radius']).toInt()}px',
          reason: 'not the 16px of the default',
        );
        await page.keyboard.press(pptr.Key.escape);
        await expectPutAway(page);
      },
    );

    test(
      'closing folds the panel to the size the style states',
      skip: skip,
      () async {
        final page = await openPage();
        addTearDown(page.close);
        const longClose = 2000;
        await configure(page, closeMs: longClose, style: styleJson(200));
        await rightClick(page);
        await _sleep(700);
        final rest = await rects(page);
        final source = _box(rest['source'])!;
        final panel = _box(rest['motion'])!;

        await page.keyboard.press(pptr.Key.escape);
        await _sleep(80);

        // Pause the fold and read it at the table's fractions of the close,
        // for the fold the style states.
        for (final row in _list(restyled['retractCurve'])) {
          final fraction = _num(row['fraction']);
          final read = _num(
            await page.evaluate<num>(
              '''
(f) => {
          const fold = document.getAnimations().find(
            (a) => a.animationName === 'co-overlay-retract');
          fold.pause();
          fold.currentTime = f * $longClose;
          return new DOMMatrix(getComputedStyle(fold.effect.target).transform).a;
        }''',
              args: [fraction],
            ),
          );
          final frame = CoreContextMenuRetract.frame(
            fraction: fraction,
            panel: panel,
            source: source,
            endScale: _num(other['retractScale']),
          );
          final where = 'at ${(fraction * 100).round()}% of the close';
          expect(read, closeTo(_num(row['scale']), 1e-3), reason: where);
          expect(read, closeTo(frame.scale, 1e-3), reason: where);
        }
      },
    );
  });
}

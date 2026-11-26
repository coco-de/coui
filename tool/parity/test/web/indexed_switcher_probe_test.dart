// How the IndexedSwitcher fade through runs, read from real Chrome.
//
// The VM test reads the emitted `transition` strings. Whether those strings
// run as a fade through — the outgoing view fading out first, the incoming
// one waiting for it, the leaving view turning hidden only at the end — is
// the browser's reading of them, and a string that names an undefined
// variable is dropped whole without an error. So this applies the switch
// the way the client does (new inline styles and `inert` on the same slot
// elements), pauses the transitions the browser starts, and reads the
// computed opacity and visibility at fixed points of the timeline.
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

/// Height of the first view; the second is taller, so the root's height
/// shows whether every slot counts toward it.
const _kHomeHeight = 80;
const _kSearchHeight = 120;

/// Milliseconds into the switch where each phase is read: inside the
/// fade-out, inside the fade-in, and past the end.
const _kInsideExit = 50;
const _kInsideEnter = 200;
const _kSettled = 400;

/// The two views. Only the live copy names its button, so the page has
/// one element per id.
List<Component> _views({required bool live}) => [
  div(
    [
      button(const [Component.text('home')], id: live ? 'home-button' : null),
    ],
    styles: const Styles(raw: {'height': '${_kHomeHeight}px'}),
  ),
  const div(
    [Component.text('search')],
    styles: Styles(raw: {'height': '${_kSearchHeight}px'}),
  ),
];

/// Applies `#next`'s slot state to `#live` — what the client's reconciler
/// does when the index changes — and samples the transitions it starts.
const _kSwitchAndSample = '''
(samples) => {
  const live = [...document.getElementById('live').children];
  const next = [...document.getElementById('next').children];
  for (const slot of live) getComputedStyle(slot).opacity;
  live.forEach((slot, i) => {
    slot.setAttribute('style', next[i].getAttribute('style'));
    if (next[i].hasAttribute('inert')) slot.setAttribute('inert', '');
    else slot.removeAttribute('inert');
  });
  for (const slot of live) getComputedStyle(slot).opacity;
  const button = document.getElementById('home-button');
  button.focus();
  const homeTakesFocus = document.activeElement === button;
  const animations = document.getAnimations();
  for (const a of animations) a.pause();
  const read = () => live.map(slot => {
    const s = getComputedStyle(slot);
    return {opacity: Number(s.opacity), visibility: s.visibility};
  });
  const out = {
    started: animations.map(a => a.transitionProperty).sort(),
    homeTakesFocus,
    rootHeight: document.getElementById('live').getBoundingClientRect().height,
    at: {},
  };
  for (const ms of samples) {
    for (const a of animations) a.currentTime = ms;
    out.at[ms] = read();
  }
  return JSON.stringify(out);
}''';

void main() {
  late pptr.Browser browser;
  late Directory work;
  late String pageUrl;

  setUpAll(() async {
    final body = await renderComponentBodyHtml(
      CoUIWeb(
        theme: .coui,
        child: div([
          div(
            [IndexedSwitcher(id: 'live', children: _views(live: true))],
            styles: const Styles(raw: {'width': '320px'}),
          ),
          div(
            [
              IndexedSwitcher(
                id: 'next',
                index: 1,
                children: _views(live: false),
              ),
            ],
            styles: const Styles(raw: {'display': 'none'}),
          ),
        ]),
      ),
    );
    work = Directory.systemTemp.createTempSync('indexed-switcher-');
    final file = File('${work.path}/index.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          // The capture harness freezes every transition for stable pixels;
          // this probe is about the transition, so it keeps them.
          animationFreezeCss: '',
        ),
      );
    pageUrl = Uri.file(file.path).toString();
    browser = await launchCaptureBrowser(width: 800, height: 600);
  });

  tearDownAll(() async {
    await browser.close();
    work.deleteSync(recursive: true);
  });

  Future<Map<String, dynamic>> switchOnce({required bool reduceMotion}) async {
    final page = await browser.newPage();
    addTearDown(page.close);
    await page.setOfflineMode(true);
    if (reduceMotion) {
      await page.emulateMediaFeatures([
        pptr.MediaFeature.prefersReducedMotion('reduce'),
      ]);
    }
    await page.goto(pageUrl, wait: .load);

    return jsonDecode(
          await page.evaluate<String>(
            _kSwitchAndSample,
            args: [
              [_kInsideExit, _kInsideEnter, _kSettled],
            ],
          ),
        )
        as Map<String, dynamic>;
  }

  Map<String, dynamic> slot(Map<String, dynamic> run, int ms, int index) =>
      ((run['at'] as Map)['$ms'] as List)[index] as Map<String, dynamic>;

  group('IndexedSwitcher in Chrome', () {
    late Map<String, dynamic> run;

    setUpAll(() async => run = await switchOnce(reduceMotion: false));

    test('the switch starts opacity transitions on both slots and a '
        'visibility one on the leaving slot', () {
      expect(run['started'], ['opacity', 'opacity', 'visibility']);
    });

    test('inside the fade-out the old view is fading and the new one has '
        'not started', () {
      final home = slot(run, _kInsideExit, 0);
      final search = slot(run, _kInsideExit, 1);
      expect(home['opacity'], inExclusiveRange(0, 1));
      expect(home['visibility'], 'visible');
      expect(search['opacity'], 0);
    });

    test('inside the fade-in the old view is hidden and the new one is '
        'arriving', () {
      final home = slot(run, _kInsideEnter, 0);
      final search = slot(run, _kInsideEnter, 1);
      expect(home['visibility'], 'hidden');
      expect(search['opacity'], inExclusiveRange(0, 1));
      expect(search['visibility'], 'visible');
    });

    test('settled, only the new view shows', () {
      expect(slot(run, _kSettled, 0)['visibility'], 'hidden');
      expect(slot(run, _kSettled, 1)['opacity'], 1);
    });

    test('the leaving view takes no focus while it fades out', () {
      expect(run['homeTakesFocus'], isFalse);
    });

    test('the root is as tall as the tallest view', () {
      expect(run['rootHeight'], _kSearchHeight);
    });
  });

  test('a reduced-motion request makes the switch instant', () async {
    final run = await switchOnce(reduceMotion: true);

    expect(run['started'], isEmpty);
    expect(slot(run, _kInsideExit, 0)['visibility'], 'hidden');
    expect(slot(run, _kInsideExit, 1)['opacity'], 1);
  });
}

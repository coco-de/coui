// A glass panel that is still fading in when the refraction runtime reaches it
// — what the runtime writes onto it, and what is left on it once the fade is
// over.
//
// The runtime appends the surface's refraction to the list the surface's
// `backdrop-filter` computes to, and writes the result inline, where it
// outranks the stylesheet. A panel reaches the runtime in the first frames of
// its open keyframe, when its list is the list at the start of the fade — a
// blur of nothing. Written as it was computed then, that list would be on the
// panel for as long as it stays open. This probe loads the shipped runtime on
// a hydrated page (`glass_fade_entry.dart`), opens a dialog and a popover,
// holds their fade half way, and reads the panel both then and when the fade
// is done.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

List<String> _chromeCandidates() => [
  if (Platform.environment['CHROME_EXECUTABLE'] case final String chrome
      when chrome.isNotEmpty)
    chrome,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
];

/// Frames, so that what the page was told to do has been done and painted.
const String _kFrames =
    '() => new Promise(r => requestAnimationFrame(() => '
    'requestAnimationFrame(() => requestAnimationFrame(r))))';

/// What the panel behind [selector] has: its computed and its inline list, the
/// progress it is at (on the page's own easing, so not the fraction of its
/// length it was held at) and its opacity.
String _read(String selector) =>
    '''
() => {
  const el = document.querySelector('$selector');
  if (!el) return null;
  return JSON.stringify({
    computed: getComputedStyle(el).backdropFilter,
    inline: el.style.getPropertyValue('backdrop-filter'),
    progress: Number(getComputedStyle(el).getPropertyValue('--coui-fade')),
    opacity: getComputedStyle(el).opacity,
  });
}''';

/// Holds every running animation of the page at [fraction] of its length.
String _hold(double fraction) =>
    '''
() => {
  for (const a of document.getAnimations()) {
    a.pause();
    a.currentTime = $fraction * a.effect.getComputedTiming().duration;
  }
}''';

/// The facts [_read] returns.
Map<String, Object?> _facts(String json) =>
    jsonDecode(json) as Map<String, Object?>;

/// The blur the preset states, which a panel at some progress draws part of.
const double _kBlur = 4;

/// `blur(…)`'s number, from a computed list.
double _blur(String list) =>
    double.parse(RegExp(r'blur\(([\d.]+)px\)').firstMatch(list)!.group(1)!);

void main() {
  final chromePath = _chromeCandidates()
      .where((candidate) => File(candidate).existsSync())
      .firstOrNull;
  final skip = chromePath == null ? 'no Chrome installed' : false;

  late Directory fixture;
  late File html;
  late pptr.Browser browser;

  setUpAll(() async {
    if (chromePath == null) return;
    fixture = Directory.systemTemp.createTempSync('coui-glass-fade-runtime-');
    final js = p.join(fixture.path, 'entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '-o',
      js,
      'tool/parity/src/web/glass_fade_entry.dart',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    // Real motion: only the capture harness freezes animations.
    html = File(p.join(fixture.path, 'index.html'))
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          surfaceStyleId: 'liquidGlass',
          animationFreezeCss: '',
        ),
      );
    browser = await launchCaptureBrowser(
      width: 800,
      height: 700,
      executablePath: chromePath,
    );
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    fixture.deleteSync(recursive: true);
  });

  /// A fresh hydrated page with the glass surface the runtime always handled
  /// on it.
  Future<pptr.Page> open() async {
    final page = await browser.newPage();
    await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
    await page.waitForFunction(
      '''
() => document.getElementById('open-dialog') !== null &&
  getComputedStyle(document.getElementById('plain-surface'))
    .backdropFilter.includes('url(')''',
    );

    return page;
  }

  /// The dialog panel, once the page has opened it.
  const dialogPanel = '.coui-dialog > [role=dialog]';

  /// Plays every animation of the page out.
  const finish =
      '() => { for (const a of document.getAnimations()) a.finish(); }';

  /// What a panel at the progress it reports draws of the blur it states.
  void expectBlurFollowsProgress(String json, {required String reason}) {
    final facts = _facts(json);
    final progress = (facts['progress']! as num).toDouble();
    final list = facts['computed']! as String;
    // Part of the way in: not at the first frame, and not done.
    expect(progress, inExclusiveRange(0.05, 0.95), reason: reason);
    expect(_blur(list), closeTo(_kBlur * progress, 0.01), reason: reason);
    // And the panel itself stays opaque: an opacity on it is what takes the
    // blur away.
    expect(double.parse(facts['opacity']! as String), 1, reason: reason);
  }

  group('a panel that is fading when the refraction runtime reaches it', () {
    test(
      'the surface the runtime always handled is written as it was',
      () async {
        final page = await open();
        try {
          final plain = await page.evaluate<String>(_read('#plain-surface'));
          // The list that surface computed to, and the bend after it. No
          // reference to a custom property: nothing about it fades.
          expect(plain, contains('blur(4px)'));
          expect(plain, contains('url('));
          expect(plain, isNot(contains('var(')));
        } finally {
          await page.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'the dialog keeps a list that follows the fade and rests on the full one',
      () async {
        final page = await open();
        try {
          await page.evaluate<void>(
            "() => document.getElementById('open-dialog').click()",
          );
          await page.waitForFunction(
            "() => document.querySelector('$dialogPanel') !== null",
          );
          // Past the runtime's first pass over the new panel, with the fade
          // still in its first frames.
          await page.evaluate<void>(_hold(0.5));
          await page.evaluate<void>(_kFrames);

          final half = await page.evaluate<String>(_read(dialogPanel));
          final list = _facts(half);
          // The bend is on the panel, so the runtime did reach it ...
          expect(list['computed'], contains('url('), reason: half);
          // ... and what it wrote is a reference to the list the stylesheet
          // states, which moves with the fade, and not the list as it was at
          // the first frame.
          expect(list['inline'], contains('var(--coui-surface-pass)'));
          expect(list['inline'], contains('url('));
          expectBlurFollowsProgress(half, reason: 'dialog half way in');

          await page.evaluate<void>(finish);
          await page.evaluate<void>(_kFrames);
          final rest = _facts(await page.evaluate<String>(_read(dialogPanel)));
          final restList = rest['computed']! as String;
          // The panel is the panel it was: the whole list, and the bend.
          expect(_blur(restList), closeTo(_kBlur, 0.01), reason: restList);
          expect(restList, contains('saturate(1.6)'));
          expect(restList, contains('brightness(0.92)'));
          expect(restList, contains('url('));
        } finally {
          await page.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'the dialog closes by the same list',
      () async {
        final page = await open();
        try {
          await page.evaluate<void>(
            "() => document.getElementById('open-dialog').click()",
          );
          await page.waitForFunction(
            "() => document.querySelector('$dialogPanel') !== null",
          );
          await page.evaluate<void>(finish);
          await page.evaluate<void>(_kFrames);
          await page.evaluate<void>(
            "() => document.getElementById('close-dialog').click()",
          );
          await page.evaluate<void>(_kFrames);
          await page.evaluate<void>(_hold(0.5));
          await page.evaluate<void>(_kFrames);

          final half = await page.evaluate<String>(_read(dialogPanel));
          expect(_facts(half)['computed'], contains('url('), reason: half);
          expectBlurFollowsProgress(half, reason: 'dialog half way out');
        } finally {
          await page.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'the popover bubble fades by its terms on a hydrated page, too',
      () async {
        final page = await open();
        try {
          await page.evaluate<void>(
            "() => document.getElementById('p-trigger').click()",
          );
          await page.waitForFunction(
            "() => document.getElementById('p-panel') !== null",
          );
          await page.evaluate<void>(_hold(0.5));
          await page.evaluate<void>(_kFrames);

          // The panel's glass is the bubble that holds the content. (The
          // runtime gives a popover's bubble no bend: it did not before the
          // fade moved, and what is asserted here is the blur.)
          Future<String> read() => page.evaluate<String>('''
() => {
            const el = document.getElementById('p-panel').closest('.coui-surface');
            return JSON.stringify({
              computed: getComputedStyle(el).backdropFilter,
              progress: Number(getComputedStyle(el).getPropertyValue('--coui-fade')),
              opacity: getComputedStyle(el).opacity,
            });
          }''');
          expectBlurFollowsProgress(
            await read(),
            reason: 'popover half way in',
          );

          await page.evaluate<void>(finish);
          await page.evaluate<void>(_kFrames);
          final rest = _facts(await read());
          expect(_blur(rest['computed']! as String), closeTo(_kBlur, 0.01));
        } finally {
          await page.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

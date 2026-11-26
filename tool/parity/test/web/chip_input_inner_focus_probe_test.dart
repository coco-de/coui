// The ChipInput's focus indicator, judged in Chrome.
//
// The frame draws the ring; the `<input>` inside it is only the line being
// typed on. A chromeless input that keeps its focus border draws a second,
// `primary`, box around that line (`CoreChipInputStyle.chromelessFieldStyle`
// turns it off). The VM test pins the class; whether the browser paints a box
// is judged here on the shipped component
// (`tool/parity/src/web/chip_input_inner_focus_entry.dart`):
//
// * focused by a mouse press or by keyboard, the input's own border is
//   transparent;
// * and the frame still wears its ring — the one indicator.
//
// A run with no Chrome on the machine is skipped, not zeroed.
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
  '/usr/bin/google-chrome-stable',
  '/usr/bin/chromium-browser',
  '/usr/bin/chromium',
];

Future<void> _settle(pptr.Page page) => page.evaluate<void>('''
() => new Promise(
  (done) => requestAnimationFrame(() => requestAnimationFrame(
    () => requestAnimationFrame(() => requestAnimationFrame(done))))
)''');

/// The painted edge of the `<input>` and the ring on the frame, as numbers.
///
/// An edge is *painted* only with a width and a style: an `<input>` with
/// `border-width: 0` keeps the browser's default border *colour* (opaque grey)
/// and draws nothing, so the colour alone says nothing about a box.
const String _kStateJs = r'''
() => {
  const frame = document.querySelector('[role="group"]');
  const input = frame.querySelector('input');
  const alpha = (c) => {
    const m = c.match(/rgba?\(([^)]+)\)/);
    if (!m) return 1;
    const parts = m[1].split(/[ ,\/]+/).filter(Boolean);
    return parts.length > 3 ? parseFloat(parts[3]) : 1;
  };
  const inCs = getComputedStyle(input);
  const paints = parseFloat(inCs.borderTopWidth) > 0 &&
      inCs.borderTopStyle !== 'none' && inCs.borderTopStyle !== 'hidden';
  const frCs = getComputedStyle(frame);
  return JSON.stringify({
    active: document.activeElement === input,
    inputBorderAlpha: paints ? alpha(inCs.borderTopColor) : 0,
    inputBorderWidth: parseFloat(inCs.borderTopWidth),
    frameRingWidth: frCs.outlineStyle === 'none' ? 0 : parseFloat(frCs.outlineWidth),
    frameRingAlpha: alpha(frCs.outlineColor),
  });
}
''';

Future<Map<String, Object?>> _state(pptr.Page page) async =>
    jsonDecode(await page.evaluate<String>(_kStateJs)) as Map<String, Object?>;

void main() {
  final candidates = _chromeCandidates();
  final chromePath = candidates
      .where((candidate) => File(candidate).existsSync())
      .firstOrNull;

  late pptr.Browser browser;
  late Directory fixture;
  late File html;

  setUpAll(() async {
    if (chromePath == null) return;
    fixture = Directory.systemTemp.createTempSync('coui-chip-inner-probe-');
    final js = p.join(fixture.path, 'entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O1',
      '-o',
      js,
      'tool/parity/src/web/chip_input_inner_focus_entry.dart',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final content = buildOfflineTailwindHarnessHtml(
      bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>',
    ).replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
    html = File(p.join(fixture.path, 'index.html'))..writeAsStringSync(content);
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    fixture.deleteSync(recursive: true);
  });

  final unsetNote = (Platform.environment['CHROME_EXECUTABLE'] ?? '').isEmpty
      ? ' (CHROME_EXECUTABLE unset)'
      : '';
  final skip = chromePath == null
      ? 'no local Chrome — tried ${candidates.join(', ')}$unsetNote; '
            'the inner focus box cannot be checked against Chrome here'
      : null;

  Future<pptr.Page> openPage() async {
    final page = await browser.newPage();
    await page.setViewport(const pptr.DeviceViewport(width: 800, height: 600));
    await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
    await page.waitForSelector('[role="group"] input');
    await _settle(page);
    return page;
  }

  group('a ChipInput', () {
    test('rests with no edge on the input and no ring', () async {
      final page = await openPage();
      try {
        final state = await _state(page);

        expect(state['active'], isFalse);
        expect(state['inputBorderAlpha'], 0);
        expect(state['frameRingAlpha'], 0);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'focused by a mouse press: the frame rings, the input has no box',
      () async {
        final page = await openPage();
        try {
          final r = await page.evaluate<String>('''
() => {
  const b = document.querySelector('[role="group"] input').getBoundingClientRect();
  return JSON.stringify({x: b.left + 4, y: b.top + b.height / 2});
}''');
          final at = jsonDecode(r) as Map<String, Object?>;
          await page.mouse.click(
            pptr.Point(
              (at['x']! as num).toDouble(),
              (at['y']! as num).toDouble(),
            ),
          );
          await _settle(page);
          final state = await _state(page);

          expect(state['active'], isTrue);
          expect(state['frameRingWidth'], 2, reason: 'the one indicator');
          expect(state['frameRingAlpha'], greaterThan(0));
          expect(
            state['inputBorderAlpha'],
            0,
            reason: 'no second, primary box around the line being typed on',
          );
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('focused by keyboard: same — the ring, and no box', () async {
      final page = await openPage();
      try {
        // The chips' remove buttons are tab stops ahead of the input; what
        // matters is a keyboard-modality focus on the input itself.
        await page.evaluate<void>('''
() => document.querySelector('[role="group"] input').focus({focusVisible: true})
''');
        await _settle(page);
        final state = await _state(page);

        expect(state['active'], isTrue);
        expect(state['frameRingWidth'], 2);
        expect(state['frameRingAlpha'], greaterThan(0));
        expect(state['inputBorderAlpha'], 0);
      } finally {
        await page.close();
      }
    }, skip: skip);
  });
}

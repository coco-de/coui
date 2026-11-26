// A press on a framed field's box, judged in Chrome.
//
// Flutter wraps the whole row of a field in one tap region: a press on its
// inset, or on a glyph beside the input, focuses the field and fires `onTap`.
// The native `<input>` only owns the pixels it covers, so the Web box takes
// the rest (`TextField._buildBoxEvents`). The VM test pins the wiring; what
// only a browser decides is judged here on the shipped components
// (`tool/parity/src/web/field_box_press_entry.dart`):
//
// * a press on the inset and on the chevron opens a Select, and a press on
//   the input itself opens it once, not twice;
// * a press on a glyph beside the input fires `onTap` and focuses the input;
// * a control inside the box — the clear button — keeps its own click and
//   does not also press the box;
// * a disabled field takes no press at all;
// * the press that focuses a field by pointer draws no outer ring, and Tab
//   into it does;
// * the pressed wash covers the whole box, with the `<input>` painting no
//   fill of its own over it.
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

/// Waits a few frames, so a state change and the render it causes have landed.
Future<void> _settle(pptr.Page page) => page.evaluate<void>('''
() => new Promise(
  (done) => requestAnimationFrame(() => requestAnimationFrame(
    () => requestAnimationFrame(() => requestAnimationFrame(done))))
)''');

/// The framed box of the field inside `#<wrapper>` — the parent of its
/// `<input>`.
const String _kBoxJs = '''
(wrapper) => {
  const input = document.querySelector('#' + wrapper + ' input');
  return input.parentElement;
}
''';

typedef _Rect = ({double x, double y, double w, double h});

Future<_Rect> _rectOf(pptr.Page page, String wrapper, String part) async {
  final raw = await page.evaluate<String>(
    '''
() => {
  const input = document.querySelector('#$wrapper input');
  const box = input.parentElement;
  const pick = {
    input: input,
    box: box,
    // The slot beside the input: the first / last child that is not the input.
    prefix: box.firstElementChild,
    suffix: box.lastElementChild,
  }['$part'];
  const r = pick.getBoundingClientRect();
  return JSON.stringify({x: r.left, y: r.top, w: r.width, h: r.height});
}
''',
  );
  final m = jsonDecode(raw) as Map<String, Object?>;
  double n(String k) => (m[k]! as num).toDouble();
  return (x: n('x'), y: n('y'), w: n('w'), h: n('h'));
}

Future<String> _active(pptr.Page page) => page.evaluate<String>('''
() => {
  const a = document.activeElement;
  if (!a) return 'none';
  return a.tagName.toLowerCase() + (a.closest('[id^="w-"]') ? ':' + a.closest('[id^="w-"]').id : '');
}
''');

Future<int> _taps(pptr.Page page, String which) async => int.parse(
  await page.evaluate<String>(
    "() => document.querySelector('#taps-$which').textContent.trim()",
  ),
);

Future<bool> _expanded(pptr.Page page) async =>
    (await page.evaluate<String>(
      "() => document.querySelector('#w-select input').getAttribute('aria-expanded')",
    )) ==
    'true';

/// The outer ring's colour alpha on the `FocusOutline` around the box — the
/// parent of the framed box.
Future<double> _ringAlpha(pptr.Page page, String wrapper) async {
  final raw = await page.evaluate<String>(
    '''
() => {
  const box = document.querySelector('#$wrapper input').parentElement;
  const c = getComputedStyle(box.parentElement).outlineColor;
  const m = c.match(/rgba?\\(([^)]+)\\)/);
  if (!m) return '1';
  const parts = m[1].split(/[ ,\\/]+/).filter(Boolean);
  return parts.length > 3 ? parts[3] : '1';
}
''',
  );
  return double.parse(raw);
}

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
    fixture = Directory.systemTemp.createTempSync('coui-field-box-probe-');
    final js = p.join(fixture.path, 'entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O1',
      '-o',
      js,
      'tool/parity/src/web/field_box_press_entry.dart',
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
      height: 800,
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
            'the box press cannot be checked against Chrome here'
      : null;

  Future<pptr.Page> openPage() async {
    final page = await browser.newPage();
    await page.setViewport(pptr.DeviceViewport(width: 800, height: 800));
    await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
    await page.waitForSelector('#w-select input');
    await _settle(page);
    return page;
  }

  Future<void> click(pptr.Page page, double x, double y) async {
    await page.mouse.click(pptr.Point(x, y));
    await _settle(page);
  }

  group('a Select', () {
    test('opens from the inset above the input, once', () async {
      final page = await openPage();
      try {
        final box = await _rectOf(page, 'w-select', 'box');
        final input = await _rectOf(page, 'w-select', 'input');
        // The box is taller than the input: the rows above it are inset.
        expect(box.h, greaterThan(input.h));
        await click(page, input.x + input.w / 2, box.y + 2);
        expect(await _expanded(page), isTrue);
        expect(await _active(page), 'input:w-select');
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('opens from the chevron', () async {
      final page = await openPage();
      try {
        final chevron = await _rectOf(page, 'w-select', 'suffix');
        await click(page, chevron.x + chevron.w / 2, chevron.y + chevron.h / 2);
        expect(await _expanded(page), isTrue);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'opens once from the input — the input is not double-counted',
      () async {
        final page = await openPage();
        try {
          final input = await _rectOf(page, 'w-select', 'input');
          await click(page, input.x + input.w / 2, input.y + input.h / 2);
          expect(await _expanded(page), isTrue);
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('a pointer press draws no outer ring', () async {
      final page = await openPage();
      try {
        final box = await _rectOf(page, 'w-select', 'box');
        final input = await _rectOf(page, 'w-select', 'input');
        await click(page, input.x + input.w / 2, box.y + 2);
        expect(await _active(page), 'input:w-select');
        expect(await _ringAlpha(page, 'w-select'), 0);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('Tab into it draws the ring', () async {
      final page = await openPage();
      try {
        await page.keyboard.press(pptr.Key.tab);
        await _settle(page);
        expect(await _active(page), 'input:w-select');
        expect(await _ringAlpha(page, 'w-select'), greaterThan(0));
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'pressing the box washes all of it; the input paints no fill',
      () async {
        final page = await openPage();
        try {
          final box = await _rectOf(page, 'w-select', 'box');
          final input = await _rectOf(page, 'w-select', 'input');
          String bg(String which) =>
              '''
() => getComputedStyle(
  document.querySelector('#w-select input')${which == 'box' ? '.parentElement' : ''}
).backgroundColor''';
          final rest = await page.evaluate<String>(bg('box'));
          expect(await page.evaluate<String>(bg('input')), 'rgba(0, 0, 0, 0)');

          await page.mouse.move(pptr.Point(input.x + 10, box.y + 2));
          await page.mouse.down();
          await _settle(page);
          expect(
            await page.evaluate<String>(bg('box')),
            isNot(rest),
            reason: 'the box steps its fill while pressed',
          );
          expect(await page.evaluate<String>(bg('input')), 'rgba(0, 0, 0, 0)');
          await page.mouse.up();
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );
  });

  group('a field with a glyph beside its input', () {
    test(
      'a press on the glyph, the inset and the input each tap once',
      () async {
        final page = await openPage();
        try {
          final glyph = await _rectOf(page, 'w-prefixed', 'prefix');
          final box = await _rectOf(page, 'w-prefixed', 'box');
          final input = await _rectOf(page, 'w-prefixed', 'input');

          await click(page, glyph.x + glyph.w / 2, glyph.y + glyph.h / 2);
          expect(await _taps(page, 'prefixed'), 1);
          expect(await _active(page), 'input:w-prefixed');

          await click(page, input.x + input.w / 2, box.y + 2);
          expect(await _taps(page, 'prefixed'), 2);

          await click(page, input.x + input.w / 2, input.y + input.h / 2);
          expect(await _taps(page, 'prefixed'), 3, reason: 'once, not twice');
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('a press on the inset keeps a focused input focused', () async {
      final page = await openPage();
      try {
        final box = await _rectOf(page, 'w-prefixed', 'box');
        final input = await _rectOf(page, 'w-prefixed', 'input');
        await click(page, input.x + input.w / 2, input.y + input.h / 2);
        expect(await _active(page), 'input:w-prefixed');

        await page.mouse.move(pptr.Point(input.x + 10, box.y + 2));
        await page.mouse.down();
        expect(
          await _active(page),
          'input:w-prefixed',
          reason: 'the press must not blur the input before the click lands',
        );
        await page.mouse.up();
      } finally {
        await page.close();
      }
    }, skip: skip);
  });

  group('a control inside the box', () {
    test('the clear button clears and does not also press the box', () async {
      final page = await openPage();
      try {
        final clear = await _rectOf(page, 'w-clearable', 'suffix');
        await click(page, clear.x + clear.w / 2, clear.y + clear.h / 2);
        expect(
          await page.evaluate<String>(
            "() => document.querySelector('#w-clearable input').value",
          ),
          '',
        );
        expect(await _taps(page, 'clearable'), 0);
      } finally {
        await page.close();
      }
    }, skip: skip);
  });

  group('a disabled field', () {
    test('takes no press and no focus', () async {
      final page = await openPage();
      try {
        final glyph = await _rectOf(page, 'w-disabled', 'prefix');
        final box = await _rectOf(page, 'w-disabled', 'box');
        await click(page, glyph.x + glyph.w / 2, glyph.y + glyph.h / 2);
        await click(page, box.x + box.w / 2, box.y + 2);
        expect(await _taps(page, 'disabled'), 0);
        expect(await _active(page), isNot('input:w-disabled'));
      } finally {
        await page.close();
      }
    }, skip: skip);
  });
}

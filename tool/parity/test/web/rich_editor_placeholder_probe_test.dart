// The placeholder of an empty Web `RichEditor`, rendered — how wide a real
// Chrome with the vendored Tailwind lays it out over the editing surface.
//
// The placeholder is the surface's `::before`, out of the flow so that it lies
// over the empty paragraph. An absolutely positioned box with no insets of its
// own is as wide as the room from where it starts to the far padding edge of
// the surface — the content and the end padding — so the placeholder wrapped
// later than the text typed in its place, and than the Flutter editor's hint,
// which wraps in the document's width. The Web unit tests read the
// declarations; this file reads the box the browser lays out, in both text
// directions, under the CSS reset the docs pages render previews under.
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

/// The width of every probe's host, in CSS px — narrow enough for the
/// placeholder to take several lines.
const double kProbeWidth = 240;

/// A feedback form's placeholder, two lines in its design.
const String _kPlaceholder =
    '응급 환자나 재진 환자를 먼저 보내야 할 때 순서를 바꿀 방법이 없어요. '
    '목록에서 끌어서 옮길 수 있으면 좋겠어요.';

const List<String> _kDirections = ['ltr', 'rtl'];

/// Same lookup as `text_field_slot_inset_probe_test.dart` — avoids
/// Puppeteer's own Chromium download so the test needs no network.
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

/// For every probe: the content box of the editing surface and that of its
/// `::before`, each as its width and its distance from the surface's padding
/// edge on the start side.
const String _kMeasureJs = '''
() => {
  const px = (v) => parseFloat(v) || 0;
  const out = {};
  for (const host of document.querySelectorAll('[data-probe]')) {
    const surface = host.querySelector('[role=textbox]');
    const s = getComputedStyle(surface);
    const b = getComputedStyle(surface, '::before');
    const start = s.direction === 'rtl' ? 'Right' : 'Left';
    // Tailwind's border-box sizing makes the used width the border box's.
    const sides = px(b.paddingLeft) + px(b.paddingRight)
        + px(b.borderLeftWidth) + px(b.borderRightWidth);
    out[host.getAttribute('data-probe')] = {
      empty: surface.hasAttribute('data-empty'),
      position: b.position,
      surfaceStart: px(s['padding' + start]),
      surfaceWidth: surface.clientWidth - px(s.paddingLeft)
          - px(s.paddingRight),
      placeholderStart: px(b[start.toLowerCase()])
          + px(b['border' + start + 'Width']) + px(b['padding' + start]),
      placeholderWidth: px(b.width) - (b.boxSizing === 'border-box' ? sides : 0),
    };
  }
  return JSON.stringify(out);
}
''';

void main() {
  final chromePath = _systemChromePath();

  late pptr.Browser browser;
  late Directory workDir;
  late Map<String, Map<String, Object?>> measured;

  setUpAll(() async {
    if (chromePath == null) return;
    workDir = Directory.systemTemp.createTempSync(
      'coui-parity-rich-editor-placeholder-',
    );
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
    final bodyHtml = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        CoUIWeb(
          theme: .coui,
          child: div([
            for (final direction in _kDirections)
              div(
                const [RichEditor(placeholder: _kPlaceholder)],
                attributes: {'data-probe': direction, 'dir': direction},
                styles: const Styles(raw: {'width': '${kProbeWidth}px'}),
              ),
          ]),
        ),
      ]),
    );
    final html = buildOfflineTailwindHarnessHtml(
      bodyHtml: bodyHtml,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>',
    );
    final file = File(p.join(workDir.path, 'placeholder.html'))
      ..writeAsStringSync(html);
    final page = await browser.newPage();
    try {
      await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
      measured = (jsonDecode(await page.evaluate<String>(_kMeasureJs)) as Map)
          .cast<String, Map<String, Object?>>();
    } finally {
      await page.close();
    }
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    workDir.deleteSync(recursive: true);
  });

  final skip = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

  group('the placeholder of an empty RichEditor in Chrome', () {
    for (final direction in _kDirections) {
      test(
        'lies over the content box, where typed text wraps ($direction)',
        () {
          final m = measured[direction]!;
          double n(String key) => (m[key]! as num).toDouble();
          // ignore: avoid_print — the measured table the report quotes.
          print('MEASURE $direction: $m');

          expect(
            m['empty'],
            isTrue,
            reason: 'the editor shows its placeholder',
          );
          expect(m['position'], 'absolute', reason: 'over the empty paragraph');
          expect(
            n('placeholderWidth'),
            closeTo(n('surfaceWidth'), 0.01),
            reason: 'it wraps in the width typed text wraps in',
          );
          expect(
            n('placeholderStart'),
            closeTo(n('surfaceStart'), 0.01),
            reason: 'it starts where typed text starts',
          );
        },
        skip: skip,
      );
    }
  });
}

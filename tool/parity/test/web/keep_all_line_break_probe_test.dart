// Text.keepAll (CSS `word-break: keep-all`) — the Chrome half of the
// shared keep-all vectors.
//
// The Web never changes the string: it renders `Text(text).keepAll` and the
// browser drops the break opportunities. Flutter has no such mode and draws
// CoreKeepAll's display string instead. The two agree only if CoreKeepAll
// removes exactly the opportunities Chrome's keep-all removes, so this file
// asks Chrome, for every join vector: lay the text out at zero width — one
// unbreakable run per line — with and without keep-all, and check the
// difference is CoreKeepAll's join set, no more and no less.
//
// The line vectors are then laid out at their real width in the vendored
// Pretendard, and must break where the table says — the same table the
// Flutter test lays out with TextPainter.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/ssr_render.dart';

/// The table shared with the Core and Flutter keep-all tests.
const String kKeepAllVectorsPath =
    'packages/coui_core/test/fixtures/keep_all_vectors.json';

/// Line height every probe is laid out with — a line index is read from
/// where a glyph's vertical centre falls, so it must not depend on the
/// fallback font a glyph came from.
const double _kLineHeightPx = 24;

/// Font size of the zero-width opportunity probes — any size works there;
/// the line vectors carry their own.
const double _kOpportunityFontSizePx = 16;

/// Same lookup as `browser_launch_test.dart` — avoids Puppeteer's own
/// Chromium download so the test needs no network.
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

/// For every `[data-probe]` element: the offsets (UTF-16, grapheme
/// starts) where a new line begins, and the text split into its lines.
///
/// A glyph's line is the line box its vertical centre falls in, so a
/// fallback font with another ascent cannot move it to a neighbour.
const String _kMeasureLinesJs = '''
() => {
  const lineHeight = %LINE_HEIGHT%;
  const segmenter = new Intl.Segmenter(undefined, {granularity: 'grapheme'});
  const out = {};
  for (const probe of document.querySelectorAll('[data-probe]')) {
    const top = probe.getBoundingClientRect().top;
    // The Text's own span — the server render may indent it inside the
    // probe box, and that whitespace is not the Text's content.
    const root = probe.firstElementChild;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const map = [];
    let text = '';
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      for (let i = 0; i < node.length; i++) map.push([node, i]);
      text += node.data;
    }
    const starts = [];
    const lines = [];
    let current = '';
    let lastLine = null;
    for (const {index, segment} of segmenter.segment(text)) {
      const [node, local] = map[index];
      const range = document.createRange();
      range.setStart(node, local);
      range.setEnd(node, local + segment.length);
      const rects = range.getClientRects();
      let line = lastLine;
      if (rects.length > 0) {
        const r = rects[0];
        line = Math.floor((r.top + r.height / 2 - top) / lineHeight);
      }
      if (lastLine !== null && line !== lastLine) {
        starts.push(index);
        lines.push(current);
        current = '';
      }
      lastLine = line;
      current += segment;
    }
    lines.push(current);
    out[probe.getAttribute('data-probe')] = {starts, lines};
  }
  return JSON.stringify(out);
}
''';

/// One probe — a fixed-width box around the production `Text` component.
Component _probe(
  String key,
  Component text, {
  required String width,
  required double fontSize,
}) {
  return div(
    [text],
    attributes: {'data-probe': key},
    styles: Styles(
      raw: {
        'width': width,
        'font-family': "'Pretendard'",
        'font-size': '${fontSize}px',
        'line-height': '${_kLineHeightPx}px',
        'white-space': 'normal',
      },
    ),
  );
}

/// Lays [probes] out in headless Chrome and returns each probe's lines.
Future<Map<String, Object?>> _measure(
  pptr.Browser browser,
  Directory workDir,
  List<Component> probes, {
  String extraStyle = '',
}) async {
  final body = await renderComponentBodyHtml(div(probes));
  final html =
      '''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>${buildLocalFontFaceCss()}</style>
<style>body{margin:0}$extraStyle</style>
</head>
<body>$body</body>
</html>
''';
  final file = File(p.join(workDir.path, 'probe.html'))
    ..writeAsStringSync(html);

  final page = await browser.newPage();
  try {
    await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
    await page.evaluate<void>('() => document.fonts.ready.then(() => {})');
    final loaded = await page.evaluate<bool>(
      "() => document.fonts.check('16px Pretendard', '가')",
    );
    if (!loaded) throw StateError('Pretendard 가 로드되지 않았다.');
    final json = await page.evaluate<String>(
      _kMeasureLinesJs.replaceAll('%LINE_HEIGHT%', '$_kLineHeightPx'),
    );

    return jsonDecode(json) as Map<String, Object?>;
  } finally {
    await page.close();
  }
}

List<int> _starts(Map<String, Object?> measured, String key) =>
    ((measured[key]! as Map<String, Object?>)['starts']! as List).cast<int>();

List<String> _lines(Map<String, Object?> measured, String key) => [
  for (final line
      in ((measured[key]! as Map<String, Object?>)['lines']! as List)
          .cast<String>())
    line.trimRight(),
];

void main() {
  final chromePath = _systemChromePath();
  final doc =
      jsonDecode(File(kKeepAllVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final joins = (doc['joins']! as List).cast<Map<String, Object?>>();
  final lines = (doc['lines']! as List).cast<Map<String, Object?>>();

  late pptr.Browser browser;
  late Directory workDir;

  setUpAll(() async {
    if (chromePath == null) return;
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
    workDir = Directory.systemTemp.createTempSync('keep-all-probe-');
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    workDir.deleteSync(recursive: true);
  });

  test(
    "Chrome's keep-all removes exactly CoreKeepAll's join set",
    () async {
      // Zero width puts every unbreakable run on its own line, so the line
      // starts are the break opportunities. `overflow-wrap: anywhere` is
      // what lets an over-long word break at any grapheme — at zero width
      // that is every grapheme — so it is switched off here to read the
      // opportunities `word-break: keep-all` leaves.
      final measured = await _measure(
        browser,
        workDir,
        [
          for (final (i, c) in joins.indexed) ...[
            _probe(
              'normal-$i',
              Text(c['input']! as String),
              width: '0',
              fontSize: _kOpportunityFontSizePx,
            ),
            _probe(
              'keepAll-$i',
              Text(c['input']! as String).keepAll,
              width: '0',
              fontSize: _kOpportunityFontSizePx,
            ),
          ],
        ],
        extraStyle:
            '[data-probe^="keepAll"] span{overflow-wrap:normal!important}',
      );

      // Every disagreement at once — one vector's failure says little
      // about which rule is off.
      final disagreements = <String>[];
      for (final (i, c) in joins.indexed) {
        final input = c['input']! as String;
        final joined = CoreKeepAll.joinOffsets(input).toSet();
        final chrome = _starts(measured, 'keepAll-$i');
        final core = [
          for (final start in _starts(measured, 'normal-$i'))
            if (!joined.contains(start)) start,
        ];
        if (chrome.join(',') != core.join(',')) {
          disagreements.add(
            '${c['name']} — ${jsonEncode(input)}: Chrome keep-all breaks '
            'at $chrome, CoreKeepAll at $core',
          );
        }
      }
      expect(disagreements, isEmpty);
    },
    skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
  );

  test(
    'the line vectors break where the table says, with and without keep-all',
    () async {
      final measured = await _measure(browser, workDir, [
        for (final (i, c) in lines.indexed) ...[
          _probe(
            'normal-$i',
            Text(c['text']! as String),
            width: '${c['width']}px',
            fontSize: (c['fontSize']! as num).toDouble(),
          ),
          _probe(
            'keepAll-$i',
            Text(c['text']! as String).keepAll,
            width: '${c['width']}px',
            fontSize: (c['fontSize']! as num).toDouble(),
          ),
        ],
      ]);

      for (final (i, c) in lines.indexed) {
        expect(
          _lines(measured, 'keepAll-$i'),
          (c['keepAll']! as List).cast<String>(),
          reason: '${c['name']} — keep-all',
        );
        expect(
          _lines(measured, 'normal-$i'),
          (c['normal']! as List).cast<String>(),
          reason: '${c['name']} — without keep-all',
        );
      }
    },
    skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
  );
}

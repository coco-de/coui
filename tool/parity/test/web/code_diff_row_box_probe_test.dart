// CodeDiff, rendered — the row box model the resolver's classes and inline
// declarations turn into in a real Chrome with the vendored Tailwind.
//
// The unit tests of the Web resolver read class names and inline
// declarations off `ResolvedCodeDiff`. That proves what is emitted, not what
// the browser makes of it, and the 21px grid lives exactly in that gap:
//
//  * a row is 21px tall only if every cell's line box is 21px AND the cells
//    do not shift against each other. A 12px gutter and a 13px body in
//    separate 21px line boxes have baselines a fraction of a pixel apart, so
//    `align-items: baseline` grows the row past 21px and the error compounds
//    down the diff.
//  * the prefix starts at x = 52 only if the gutter `width` is the cell's
//    TOTAL width. coui_web ships without Tailwind's preflight, so a bare
//    `div` is content-box and the 12px gap would be added on top.
//
// The colours are read the same way: the band an added / removed row paints
// and the ink of its prefix, number and code are the *computed* values after
// the theme's CSS variables resolve, so an alpha that survived into the band
// (the retired tint) or a variable that resolved to nothing shows up here and
// not in the unit tests that read the declarations.
//
// The markup is the real component's server output, so a change to what
// `CodeDiff` emits changes what this test looks at. The fonts are the
// vendored Geist Mono the Flutter side bundles, so the ascent and descent
// the baseline question turns on are the real ones.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../../src/normalize/css_value_parsers.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';

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

const List<CoreCodeDiffLine> _kLines = [
  CoreCodeDiffLine(text: 'unchanged', type: .unchanged, lineNumber: 1),
  CoreCodeDiffLine(text: 'removed', type: .removed, lineNumber: 2),
  CoreCodeDiffLine(text: 'added', type: .added, lineNumber: 3),
  CoreCodeDiffLine(text: 'unchanged again', type: .unchanged, lineNumber: 4),
  CoreCodeDiffLine(text: 'added again', type: .added, lineNumber: 5),
  CoreCodeDiffLine(text: 'removed again', type: .removed, lineNumber: 6),
];

const String _kMeasure = '''
() => {
  const root = document.getElementById('cd');
  const rows = [...root.querySelectorAll('.flex-row')];
  const rect = (el) => {
    const r = el.getBoundingClientRect();
    return {left: r.left, top: r.top, width: r.width, height: r.height};
  };
  const style = (el) => {
    const cs = getComputedStyle(el);
    return {
      fontSize: cs.fontSize, lineHeight: cs.lineHeight,
      fontFamily: cs.fontFamily, textAlign: cs.textAlign,
      boxSizing: cs.boxSizing,
      color: cs.color, backgroundColor: cs.backgroundColor,
      borderTopWidth: cs.borderTopWidth, borderTopColor: cs.borderTopColor,
      paddingLeft: cs.paddingLeft, paddingRight: cs.paddingRight,
      paddingTop: cs.paddingTop, paddingBottom: cs.paddingBottom,
      alignItems: cs.alignItems,
    };
  };
  return JSON.stringify({
    wrapper: rect(rows[0].parentElement),
    rows: rows.map((row) => ({
      blockStyle: style(root),
      row: rect(row),
      rowStyle: style(row),
      gutter: rect(row.children[0]),
      gutterStyle: style(row.children[0]),
      prefix: rect(row.children[1]),
      prefixStyle: style(row.children[1]),
      text: rect(row.children[2]),
      textStyle: style(row.children[2]),
    })),
  });
}
''';

/// The page the component is laid out in.
const double _kPageWidthPx = 600;

/// The 21px line box every code role stands on.
const double _kLineBoxPx = 21;

/// Where the `+ ` / `- ` prefix starts: the row's 12px inset, then the
/// gutter cell's 40px total width (a 28px digit column and a 12px gap).
const double _kPrefixXPx = 52;

const double _kGutterWidthPx = 40;
const double _kGapPx = 12;
const double _kDigitColumnPx = 28;

/// Well inside one layout unit — the rows are exact, not "about 21".
const double _kEpsilon = 0.01;

class _Row {
  _Row(this.json);

  final Map<String, dynamic> json;

  Map<String, dynamic> _map(String key) => json[key] as Map<String, dynamic>;

  Map<String, dynamic> get row => _map('row');
  Map<String, dynamic> get gutter => _map('gutter');
  Map<String, dynamic> get prefix => _map('prefix');
  Map<String, dynamic> get text => _map('text');
  Map<String, dynamic> get rowStyle => _map('rowStyle');
  Map<String, dynamic> get blockStyle => _map('blockStyle');
  Map<String, dynamic> get gutterStyle => _map('gutterStyle');
  Map<String, dynamic> get prefixStyle => _map('prefixStyle');
  Map<String, dynamic> get textStyle => _map('textStyle');
}

double _n(Map<String, dynamic> rect, String key) =>
    (rect[key] as num).toDouble();

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();

  late String bodyHtml;

  testServer('server output of the CodeDiff under test', (tester) async {
    tester.pumpComponent(
      Theme.defaults(
        child: const CodeDiff(id: 'cd', lines: _kLines),
      ),
    );
    final response = await tester.request('/');
    final match = RegExp(
      '<body[^>]*>(.*)</body>',
      dotAll: true,
    ).firstMatch(response.body);
    bodyHtml = match == null ? response.body : match.group(1)!;
    expect(bodyHtml, contains('id="cd"'));
  });

  final skip = chromePath == null
      ? 'no local Chrome — the rendered claims cannot be verified here'
      : null;

  group('CodeDiff rendered by the vendored Tailwind in Chrome', () {
    late pptr.Browser browser;
    late pptr.Page page;
    late Directory tempDir;

    setUpAll(() async {
      browser = await pptr.puppeteer.launch(executablePath: chromePath);
    });
    tearDownAll(() => browser.close());

    setUp(() async {
      page = await browser.newPage();
      tempDir = Directory.systemTemp.createTempSync('coui-code-diff-box-');
    });
    tearDown(() async {
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    /// Lays the component out and measures every row. [extraStyle] is how the
    /// controls break one property at a time; [dir] flips the reading
    /// direction on the root, as the locale does.
    Future<List<_Row>> measure({
      String extraStyle = '',
      String dir = 'ltr',
    }) async {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: bodyHtml,
        themeConfig: themeConfig,
        vendoredTailwindScript: vendoredScript,
        additionalHeadHtml:
            '<style>${buildLocalFontFaceCss()}</style>'
            '<style>body{margin:0;width:${_kPageWidthPx}px}$extraStyle</style>',
      ).replaceFirst('<html ', '<html dir="$dir" ');
      final file = File(p.join(tempDir.path, 'code_diff.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: pptr.Until.load);
      await page.evaluate<void>('() => document.fonts.ready.then(() => {})');
      final measured =
          jsonDecode(await page.evaluate<String>(_kMeasure))
              as Map<String, dynamic>;

      return [
        for (final r in (measured['rows'] as List).cast<Map<String, dynamic>>())
          _Row(r),
      ];
    }

    test('every row is exactly 21px tall and rows abut', () async {
      final rows = await measure();

      expect(rows, hasLength(_kLines.length));
      for (final (i, r) in rows.indexed) {
        expect(
          _n(r.row, 'height'),
          closeTo(_kLineBoxPx, _kEpsilon),
          reason: 'row $i is not on the 21px grid',
        );
        // Abutting: row i starts where the 21px grid says, not a rounding
        // error later — an extra fraction per row compounds down the diff.
        expect(_n(r.row, 'top'), closeTo(i * _kLineBoxPx, _kEpsilon));
      }
    });

    test('the cells stand on the same 21px line box', () async {
      final rows = await measure();

      for (final r in rows) {
        for (final cell in [r.gutter, r.prefix, r.text]) {
          expect(_n(cell, 'height'), closeTo(_kLineBoxPx, _kEpsilon));
          expect(_n(cell, 'top'), closeTo(_n(r.row, 'top'), _kEpsilon));
        }
        expect(
          parseCssFlexAlignment(r.rowStyle['alignItems'] as String),
          'flex-start',
        );
        expect(r.rowStyle['paddingTop'], '0px');
        expect(r.rowStyle['paddingBottom'], '0px');
        expect(r.gutterStyle['paddingTop'], '0px');
        expect(r.gutterStyle['paddingBottom'], '0px');
      }
    });

    test('control — baseline alignment would grow the row past 21px', () async {
      // The reason the row is start-aligned. A 12px gutter and a 13px body
      // each sit in their own 21px line box; their baselines are a fraction
      // of a pixel apart, and aligning baselines shifts one cell down by
      // it. If this control stopped growing the row, the choice would be
      // unmotivated by this font and worth revisiting.
      final rows = await measure(
        extraStyle: '#cd .flex-row{align-items:baseline !important}',
      );

      expect(_n(rows.first.row, 'height'), greaterThan(_kLineBoxPx));
    });

    test('the prefix starts at x = 52: 12 inset + 40 gutter cell', () async {
      final rows = await measure();

      for (final r in rows) {
        expect(_n(r.gutter, 'left') - _n(r.row, 'left'), _kGapPx);
        expect(_n(r.gutter, 'width'), _kGutterWidthPx);
        expect(_n(r.prefix, 'left') - _n(r.row, 'left'), _kPrefixXPx);
      }
    });

    test(
      'the gutter cell is border-box: padding sits inside its width',
      () async {
        final rows = await measure();
        final gutter = rows.first.gutterStyle;

        expect(gutter['boxSizing'], 'border-box');
        // 40 total, minus the 12px end gap, leaves the 28px digit column.
        final digitColumn =
            _n(rows.first.gutter, 'width') -
            double.parse(
              (gutter['paddingLeft'] as String).replaceAll('px', ''),
            ) -
            double.parse(
              (gutter['paddingRight'] as String).replaceAll('px', ''),
            );
        expect(digitColumn, _kDigitColumnPx);
      },
    );

    test(
      'control — a content-box gutter would push the prefix to 64',
      () async {
        // coui_web ships without Tailwind's preflight, so a bare `div` is
        // content-box. This is what the inline `box-sizing` guards against.
        final rows = await measure(
          extraStyle: '#cd .text-end{box-sizing:content-box !important}',
        );

        expect(
          _n(rows.first.prefix, 'left') - _n(rows.first.row, 'left'),
          _kPrefixXPx + _kGapPx,
        );
      },
    );

    test('the row fits its container: its inset is inside its width', () async {
      final rows = await measure();

      for (final r in rows) {
        expect(r.rowStyle['boxSizing'], 'border-box');
        expect(_n(r.row, 'width'), _kPageWidthPx);
      }
    });

    test(
      'gutter is Geist Mono 12 and body Geist Mono 13, both on 21px',
      () async {
        final r = (await measure()).first;

        expect(r.gutterStyle['fontSize'], '12px');
        expect(r.gutterStyle['lineHeight'], '21px');
        expect(r.prefixStyle['fontSize'], '13px');
        expect(r.prefixStyle['lineHeight'], '21px');
        expect(r.textStyle['fontSize'], '13px');
        expect(r.textStyle['lineHeight'], '21px');
        for (final family in [
          r.gutterStyle['fontFamily'],
          r.prefixStyle['fontFamily'],
          r.textStyle['fontFamily'],
        ]) {
          expect(family, startsWith('"${CoreFontFamily.mono}"'));
        }
      },
    );

    test('the block is a surfaceContainerLow face with no border', () async {
      final block = (await measure()).first.blockStyle;
      final scheme = CouiColorPresets.source.light().resolved(.light);
      final face = scheme.resolve(
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );

      expect(
        block['backgroundColor'],
        'rgb(${face.red}, ${face.green}, ${face.blue})',
      );
      // Told apart by its face alone: no stroke on the side the browser draws.
      expect(block['borderTopWidth'], '0px');
    });

    test(
      'the browser paints opaque bands and the ink of each row type',
      () async {
        final rows = await measure();
        final scheme = CouiColorPresets.source.light().resolved(.light);
        String rgb(CoreColorToken token) {
          final c = scheme.resolve(CoreColor.token(token));
          return 'rgb(${c.red}, ${c.green}, ${c.blue})';
        }

        final success = rgb(CoreColors.successContainer);
        final error = rgb(CoreColors.errorContainer);
        final bodyInk = rgb(CoreColors.onSurface);

        for (final (i, r) in rows.indexed) {
          final type = _kLines[i].type;
          final reason = 'row $i ($type)';
          // The code is the body ink on every row: a band never recolours it.
          expect(r.textStyle['color'], bodyInk, reason: reason);

          switch (type) {
            case CoreCodeDiffLineType.added:
              // `rgb(r, g, b)` with no alpha component is an opaque band.
              expect(r.rowStyle['backgroundColor'], success, reason: reason);
              expect(
                r.prefixStyle['color'],
                rgb(CoreColors.onSuccessContainer),
                reason: reason,
              );
              expect(
                r.gutterStyle['color'],
                rgb(CoreColors.onSuccessContainer),
                reason: reason,
              );
            case CoreCodeDiffLineType.removed:
              expect(r.rowStyle['backgroundColor'], error, reason: reason);
              expect(
                r.prefixStyle['color'],
                rgb(CoreColors.onErrorContainer),
                reason: reason,
              );
              expect(
                r.gutterStyle['color'],
                rgb(CoreColors.onErrorContainer),
                reason: reason,
              );
            case CoreCodeDiffLineType.unchanged:
              // No band, and the plain gutter number is the opaque
              // onSurfaceVariant — never a dimmed copy of it.
              expect(
                r.rowStyle['backgroundColor'],
                'rgba(0, 0, 0, 0)',
                reason: reason,
              );
              expect(
                r.gutterStyle['color'],
                rgb(CoreColors.onSurfaceVariant),
                reason: reason,
              );
              expect(r.prefixStyle['color'], bodyInk, reason: reason);
          }
        }
      },
    );

    test(
      'the gap is on the right and the number right-aligned in LTR',
      () async {
        final g = (await measure()).first.gutterStyle;

        expect(g['paddingRight'], '12px');
        expect(g['paddingLeft'], '0px');
        expect(g['textAlign'], 'end');
      },
    );

    test('the gap flips to the left in RTL, the cell stays 40 wide', () async {
      final r = (await measure(dir: 'rtl')).first;

      expect(r.gutterStyle['paddingLeft'], '12px');
      expect(r.gutterStyle['paddingRight'], '0px');
      expect(r.gutterStyle['textAlign'], 'end');
      expect(_n(r.gutter, 'width'), _kGutterWidthPx);
      // Mirrored: the prefix sits to the left of the gutter cell and the two
      // abut — the 12px gap is the gutter cell's own left padding.
      expect(
        _n(r.gutter, 'left') - (_n(r.prefix, 'left') + _n(r.prefix, 'width')),
        0,
      );
    });
  }, skip: skip);
}

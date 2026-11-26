// AppBar's centred title, rendered — where a real Chrome with the vendored
// Tailwind puts the title of a centred single-row bar.
//
// The Web resolver's unit tests read the grid it emits (three columns, the
// title in the middle one). That proves the declarations, not the layout, and
// the claim lives in the layout: both side columns are held at the wider
// cluster's width (`--coui-app-bar-side`, which the client-side measurer
// writes), so the title stands on the centre of the whole bar and, when it
// is too long, ends in an ellipsis inside the symmetric room
// `W - 2 * max(L, T) - 2 * g` instead of shifting.
//
// Each case is checked against the closed-form rule the Flutter twin's layout
// delegate implements (`coui_flutter/test/components/layout/
// app_bar_center_title_test.dart` checks Flutter against the same rule).
//
// The markup is the real component's server output, loaded without its
// client runtime, so the measurer does not run here: [_applySide] writes the
// variable the way the measurer does (the wider cluster's measured width).
// The last case loads the page without it — the server-rendered first paint,
// where each side falls back to its own `max-content`.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

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

/// The page — and so the bar — width.
const double _kPageWidthPx = 480;

/// The "back · title · two text actions" clusters: unequal on purpose.
const double _kLeadingPx = 40;
const double _kTrailingPx = 120;

/// Within a layout unit — the grid's track sizes are exact.
const double _kEpsilon = 0.05;

Component _box(String id, double width) => div(
  const [],
  id: id,
  styles: Styles(
    raw: {'width': '${width}px', 'height': '20px', 'display': 'block'},
  ),
);

Component _bar(
  String id, {
  Component? title,
  Component? trailing,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
}) => div([
  AppBar(
    id: id,
    centerTitle: true,
    showDivider: false,
    appBarStyle: CoreAppBarStyle(surfaceStyle: surfaceStyle),
    leading: [_box('$id-l', _kLeadingPx)],
    trailing: [trailing ?? _box('$id-r', _kTrailingPx)],
    title: title ?? _box('$id-t', 100),
  ),
]);

/// A trailing cluster of words — narrower when wrapped than on one line, so
/// a grid that let a long title squeeze it would show.
const _kWords = Text('Search more actions');

/// What the client-side measurer does to bar [id]: writes the wider
/// cluster's width to `--coui-app-bar-side` on the root.
String _applySide(String id) =>
    '''
() => {
  const bar = document.getElementById('$id');
  const widths = ['[data-coui-app-bar-leading]', '[data-coui-app-bar-trailing]']
    .map((s) => bar.querySelector(':scope > ' + s))
    .filter((el) => el != null)
    .map((el) => el.getBoundingClientRect().width);
  bar.style.setProperty('--coui-app-bar-side', Math.max(0, ...widths) + 'px');
}
''';

/// Measures the bar [id]: its content box, the two clusters as laid out and
/// the title slot (the grid's middle cell). With [titleWidth] the title box
/// is resized first — the wide case is sized from the measured bar.
String _measure(String id, {String? titleWidth}) =>
    '''
() => {
  const middle = (bar) => [...bar.children].find(
    (el) => getComputedStyle(el).gridColumnStart === '2');
  const bar = document.getElementById('$id');
  const title = document.getElementById('$id-t');
  ${titleWidth == null ? '' : '''
  {
    const cs = getComputedStyle(bar);
    const wrapper = middle(bar);
    const ws = getComputedStyle(wrapper);
    const lead = bar.querySelector('[data-coui-app-bar-leading]');
    const trail = bar.querySelector('[data-coui-app-bar-trailing]');
    const W = bar.getBoundingClientRect().width
      - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
    const g = parseFloat(cs.columnGap);
    const L = lead.getBoundingClientRect().width;
    const T = trail.getBoundingClientRect().width;
    const pad = parseFloat(ws.paddingLeft) + parseFloat(ws.paddingRight);
    const width = $titleWidth;
    title.style.width = width + 'px';
  }'''}
  const cs = getComputedStyle(bar);
  const rect = (el) => {
    const r = el.getBoundingClientRect();
    return {left: r.left, right: r.right, width: r.width};
  };
  const wrapper = middle(bar);
  const line = wrapper.querySelector('.truncate');
  return JSON.stringify({
    bar: rect(bar),
    padLeft: parseFloat(cs.paddingLeft),
    padRight: parseFloat(cs.paddingRight),
    gap: parseFloat(cs.columnGap),
    display: cs.display,
    leading: rect(bar.querySelector('[data-coui-app-bar-leading]')),
    trailing: rect(bar.querySelector('[data-coui-app-bar-trailing]')),
    slot: rect(wrapper),
    lineOverflows: line == null ? null : line.scrollWidth > line.clientWidth,
    lineTextOverflow: line == null ? null : getComputedStyle(line).textOverflow,
  });
}
''';

class _Bar {
  _Bar(this.json);

  final Map<String, dynamic> json;

  double _n(String key) => (json[key] as num).toDouble();
  double _r(String rect, String key) =>
      ((json[rect] as Map<String, dynamic>)[key] as num).toDouble();

  double get gap => _n('gap');

  /// The content box — the bar minus its padding.
  double get contentLeft => _r('bar', 'left') + _n('padLeft');
  double get contentRight => _r('bar', 'right') - _n('padRight');
  double get width => contentRight - contentLeft;

  double get leading => _r('leading', 'width');
  double get trailing => _r('trailing', 'width');
  double get slot => _r('slot', 'width');
  double get slotLeft => _r('slot', 'left');
  double get slotRight => _r('slot', 'right');

  /// The symmetric room the rule leaves the title slot.
  double get room => width - 2 * math.max(leading, trailing) - 2 * gap;

  /// The content box's centre.
  double get centre => (contentLeft + contentRight) / 2;

  /// The title slot's centre.
  double get slotCentre => (slotLeft + slotRight) / 2;
}

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();

  late String bodyHtml;

  testServer('server output of the AppBars under test', (tester) async {
    tester.pumpComponent(
      Theme.defaults(
        child: div([
          _bar('fit'),
          _bar('wide'),
          _bar('long', title: Text('Title ' * 40)),
          _bar('glass', surfaceStyle: .liquidGlass),
          _bar('words', trailing: _kWords),
          _bar('words-long', title: Text('Title ' * 40), trailing: _kWords),
        ]),
      ),
    );
    final response = await tester.request('/');
    final match = RegExp(
      '<body[^>]*>(.*)</body>',
      dotAll: true,
    ).firstMatch(response.body);
    bodyHtml = match == null ? response.body : match.group(1)!;
    expect(bodyHtml, contains('id="wide"'));
  });

  final skip = chromePath == null
      ? 'no local Chrome — the rendered claims cannot be verified here'
      : null;

  group('AppBar centred title rendered by the vendored Tailwind in Chrome', () {
    late pptr.Browser browser;
    late pptr.Page page;
    late Directory tempDir;

    setUpAll(() async {
      browser = await pptr.puppeteer.launch(executablePath: chromePath);
    });
    tearDownAll(() => browser.close());

    setUp(() async {
      page = await browser.newPage();
      tempDir = Directory.systemTemp.createTempSync('coui-app-bar-centre-');
    });
    tearDown(() async {
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    Future<void> load({String dir = 'ltr'}) async {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: bodyHtml,
        themeConfig: themeConfig,
        vendoredTailwindScript: vendoredScript,
        additionalHeadHtml:
            '<style>${buildLocalFontFaceCss()}</style>'
            '<style>body{margin:0;width:${_kPageWidthPx}px}</style>',
      ).replaceFirst('<html ', '<html dir="$dir" ');
      final file = File(p.join(tempDir.path, 'app_bar.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: pptr.Until.load);
      await page.evaluate<void>('() => document.fonts.ready.then(() => {})');
    }

    Future<_Bar> measure(
      String id, {
      String? titleWidth,
      bool measured = true,
    }) async {
      if (measured) await page.evaluate<void>(_applySide(id));
      return _Bar(
        jsonDecode(
              await page.evaluate<String>(_measure(id, titleWidth: titleWidth)),
            )
            as Map<String, dynamic>,
      );
    }

    /// The wide case: 20px wider than the symmetric room.
    const wideWidth = 'W - 2 * Math.max(L, T) - 2 * g + 20 - pad';

    test('a title that fits sits on the centre of the whole bar', () async {
      await load();
      for (final id in ['fit', 'glass']) {
        final bar = await measure(id);

        expect(bar.json['display'], 'grid', reason: id);
        expect(
          bar.slotCentre,
          closeTo(bar.centre, _kEpsilon),
          reason: '$id — on the bar, not between unequal clusters',
        );
        expect(bar.trailing - bar.leading, greaterThan(40), reason: id);
      }
    }, skip: skip);

    test(
      'a title wider than the symmetric room stays centred and gives way',
      () async {
        await load();
        final bar = await measure('wide', titleWidth: wideWidth);
        final trailingLeft = bar.contentRight - bar.trailing;

        expect(bar.slot, closeTo(bar.room, _kEpsilon));
        expect(bar.slotCentre, closeTo(bar.centre, _kEpsilon));
        expect(trailingLeft - bar.slotRight, closeTo(bar.gap, _kEpsilon));
      },
      skip: skip,
    );

    test(
      'a title that cannot fit gets the symmetric room and an ellipsis',
      () async {
        await load();
        final bar = await measure('long');

        expect(bar.slot, closeTo(bar.room, _kEpsilon));
        expect(bar.slotCentre, closeTo(bar.centre, _kEpsilon));
        expect(bar.json['lineOverflows'], isTrue);
        expect(bar.json['lineTextOverflow'], 'ellipsis');
      },
      skip: skip,
    );

    test(
      'a long title does not squeeze a cluster of words',
      () async {
        await load();
        final short = await measure('words');
        final long = await measure('words-long');

        // The cluster keeps its one-line width; the title gives way.
        expect(long.trailing, closeTo(short.trailing, _kEpsilon));
        expect(long.slot, closeTo(long.room, _kEpsilon));
        expect(long.slotCentre, closeTo(long.centre, _kEpsilon));
        expect(long.json['lineOverflows'], isTrue);
      },
      skip: skip,
    );

    test(
      'right to left holds the title on the centre too',
      () async {
        await load(dir: 'rtl');
        final bar = await measure('wide', titleWidth: wideWidth);

        expect(bar.slot, closeTo(bar.room, _kEpsilon));
        expect(bar.slotCentre, closeTo(bar.centre, _kEpsilon));
        // The trailing cluster is on the left now.
        expect(
          bar.slotLeft - (bar.contentLeft + bar.trailing),
          closeTo(bar.gap, _kEpsilon),
        );
      },
      skip: skip,
    );

    test(
      'before the measurer runs, each side falls back to its own cluster',
      () async {
        // The server-rendered first paint: a title that fits is already on
        // the centre; one that cannot fit takes the room between the
        // clusters until the variable is written.
        await load();
        final fit = await measure('fit', measured: false);
        final long = await measure('long', measured: false);

        expect(fit.slotCentre, closeTo(fit.centre, _kEpsilon));
        expect(
          long.slot,
          closeTo(
            long.width - long.leading - long.trailing - 2 * long.gap,
            _kEpsilon,
          ),
        );
      },
      skip: skip,
    );
  }, skip: skip);
}

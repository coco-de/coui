// A Banner, rendered — where a real Chrome with the vendored Tailwind puts
// the trailing group (action + dismiss) of the component's own server output.
//
// The Web unit tests read the markup: a wrapping body, the message column
// growing from `contentMinWidth`, the trailing group at its own width. That
// proves the declarations, not the layout, and the claim lives in the layout:
// at a wide width the trailing group shares the message's line, centred on
// it; at a narrow one it moves below, `trailingRunSpacing` down, starting
// where the message TEXT starts — after the icon. Flutter lays the same
// banner out in `banner_wrap_test.dart`; this file measures the DOM.
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

/// Host widths in CSS px: one where everything fits on one line, one a
/// phone's width where the trailing group has to wrap, and a sweep between.
const double kWide = 600;
const double kNarrow = 320;
const List<double> kSweep = [
  280,
  300,
  320,
  340,
  360,
  380,
  400,
  420,
  440,
  460,
  480,
  500,
  520,
  540,
  560,
];

/// Same lookup as `dock_bar_height_probe_test.dart` — avoids Puppeteer's own
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

String _id(double width, {bool action = true}) =>
    'banner-${width.toInt()}${action ? '' : '-dismiss'}';

Component _probe(double width, {bool action = true}) => div(
  [
    Banner(
      message: const span(
        [Component.text('Your trial ends in three days.')],
        attributes: {'data-part': 'message'},
      ),
      description: const Component.text('Upgrade to keep your projects.'),
      variant: .info,
      onDismiss: () {},
      action: action
          ? Button(
              variant: .outline,
              size: .sm,
              onPressed: () {},
              child: const Component.text('Upgrade'),
            )
          : null,
    ),
  ],
  attributes: {'data-probe': _id(width, action: action)},
  styles: Styles(raw: {'width': '${width}px'}),
);

/// For every probe: the message text, the message column, the trailing
/// group, and the action and dismiss buttons.
const String _kMeasureJs = '''
() => {
  const rect = (el) => {
    if (!el) return null;
    const r = el.getBoundingClientRect();
    return {left: r.left, right: r.right, top: r.top, bottom: r.bottom};
  };
  const out = {};
  for (const host of document.querySelectorAll('[data-probe]')) {
    const body = host.querySelector('.flex-wrap');
    const [column, trailing] = [...body.children];
    const buttons = [...trailing.querySelectorAll('button, [role="button"]')];
    out[host.getAttribute('data-probe')] = {
      text: rect(host.querySelector('[data-part="message"]')),
      column: rect(column),
      trailing: rect(trailing),
      first: rect(buttons[0]),
      icon: rect(host.querySelector('[data-icon^="lucide:"]:not([data-icon="lucide:x"])')),
    };
  }
  return JSON.stringify(out);
}
''';

typedef _Rect = ({double left, double right, double top, double bottom});

_Rect _rect(Object? json) {
  final map = json! as Map<String, Object?>;
  double n(String key) => (map[key]! as num).toDouble();

  return (
    left: n('left'),
    right: n('right'),
    top: n('top'),
    bottom: n('bottom'),
  );
}

double _centre(_Rect r) => (r.top + r.bottom) / 2;

class _Probe {
  _Probe(Map<String, Object?> json)
    : text = _rect(json['text']),
      column = _rect(json['column']),
      trailing = _rect(json['trailing']),
      first = _rect(json['first']),
      icon = _rect(json['icon']);

  final _Rect text;
  final _Rect column;
  final _Rect trailing;
  final _Rect first;
  final _Rect icon;

  bool get oneLine => trailing.top < column.bottom;
}

void main() {
  final chromePath = _systemChromePath();
  late pptr.Browser browser;
  late Directory workDir;
  late Map<String, _Probe> measured;

  setUpAll(() async {
    if (chromePath == null) return;
    workDir = Directory.systemTemp.createTempSync('banner-wrap-probe-');
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        Theme.defaults(
          child: div([
            _probe(kWide),
            _probe(kNarrow),
            _probe(kWide, action: false),
            for (final w in kSweep) _probe(w),
          ]),
        ),
      ]),
    );
    final html = buildOfflineTailwindHarnessHtml(
      bodyHtml: body,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>',
    );
    final file = File(p.join(workDir.path, 'banner.html'))
      ..writeAsStringSync(html);
    final page = await browser.newPage();
    try {
      await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
      final json =
          jsonDecode(await page.evaluate<String>(_kMeasureJs))
              as Map<String, Object?>;
      measured = {
        for (final e in json.entries)
          e.key: _Probe(e.value! as Map<String, Object?>),
      };
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

  group('a Banner in Chrome', () {
    test('wide: the trailing group shares the message line', () {
      final probe = measured[_id(kWide)]!;
      expect(probe.oneLine, isTrue);
      expect(_centre(probe.trailing), closeTo(_centre(probe.column), 0.5));
      expect(probe.trailing.left - probe.column.right, closeTo(12, 0.5));
    }, skip: skip);

    test('narrow: the trailing group wraps under the message text', () {
      final probe = measured[_id(kNarrow)]!;
      expect(probe.oneLine, isFalse);
      expect(probe.trailing.left, closeTo(probe.text.left, 0.5));
      expect(probe.first.left, closeTo(probe.text.left, 0.5));
      expect(probe.trailing.top - probe.column.bottom, closeTo(8, 0.5));
    }, skip: skip);

    test('wrapped: the icon centres on the message block', () {
      final probe = measured[_id(kNarrow)]!;
      expect(probe.oneLine, isFalse);
      expect(_centre(probe.icon), closeTo(_centre(probe.column), 0.5));
      expect(probe.text.left - probe.icon.right, closeTo(12, 0.5));
    }, skip: skip);

    test('one line: the icon centres on the row', () {
      final probe = measured[_id(kWide)]!;
      expect(_centre(probe.icon), closeTo(_centre(probe.column), 0.5));
      expect(_centre(probe.icon), closeTo(_centre(probe.trailing), 0.5));
    }, skip: skip);

    test('dismiss only: the dismiss gap on one line', () {
      final probe = measured[_id(kWide, action: false)]!;
      expect(probe.oneLine, isTrue);
      expect(probe.trailing.left - probe.column.right, closeTo(8, 0.5));
    }, skip: skip);

    test('the column is never narrower than 240 while on one line', () {
      var sawOneLine = false;
      var sawWrapped = false;
      for (final w in kSweep) {
        final probe = measured[_id(w)]!;
        if (probe.oneLine) {
          sawOneLine = true;
          final width = probe.column.right - probe.column.left;
          expect(width, greaterThanOrEqualTo(239.5), reason: 'one line at $w');
        } else {
          sawWrapped = true;
        }
      }
      expect(sawOneLine, isTrue);
      expect(sawWrapped, isTrue);
    }, skip: skip);
  });
}

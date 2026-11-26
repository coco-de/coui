// A labelled Divider, rendered — where a real Chrome with the vendored
// Tailwind puts the label and the two line segments of the component's own
// server output.
//
// The Web resolver's unit tests read the markup it emits. That proves the
// declarations, not the layout, and the claim lives in the layout: the label
// stays where the divider's own box says it goes when the two insets are
// unequal, and each inset is held inside its segment, so it only shortens the
// line. Flutter lays the same divider out from the same inputs; the vector
// table `divider_label_vectors.json` is what that layout comes to, and
// `divider_label_position_test.dart` in coui_flutter measures the widget tree
// against it. This file measures the DOM against it, in both text directions,
// so a layout change on one platform fails the other.
//
// Every number is a rect the browser laid out — the divider's own box, the
// label's and the two line elements' — converted to the same frame as the
// table: along the main axis, from the box's start edge in reading order.
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

/// The table shared with the Core reference test and the Flutter widget test.
const String kDividerLabelVectorsPath =
    'packages/coui_core/test/fixtures/divider_label_vectors.json';

/// Same lookup as `keep_all_line_break_probe_test.dart` — avoids Puppeteer's
/// own Chromium download so the test needs no network.
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

/// A span along the divider's main axis, measured from the box's start edge.
typedef _Span = ({double start, double end});

/// One row of the table.
class _Case {
  _Case(this.json);

  final Map<String, Object?> json;

  String get name => json['name']! as String;
  bool get horizontal => json['orientation'] == 'horizontal';
  double _n(String key) => (json[key]! as num).toDouble();
  double get box => _n('box');
  double get label => _n('label');
  double get childPadding => _n('childPadding');
  double get indent => _n('indent');
  double get endIndent => _n('endIndent');
  CoreDividerChildAlignment get alignment =>
      CoreDividerChildAlignment.values.byName(json['alignment']! as String);
  double get labelCentre => _n('labelCentre');

  /// The text directions this row holds in, when it narrows the table's.
  List<String>? get directions => (json['directions'] as List?)?.cast<String>();

  /// The two expected segments in reading order, `null` where a segment has no
  /// length.
  List<_Span?> get lines => [
    for (final line in (json['lines']! as List).cast<Map<String, Object?>?>())
      if (line == null)
        null
      else
        (
          start: (line['start']! as num).toDouble(),
          end: (line['end']! as num).toDouble(),
        ),
  ];
}

/// One row of the table's `intrinsic` section: a divider whose parent takes
/// its width from its content.
class _Intrinsic {
  _Intrinsic(this.json);

  final Map<String, Object?> json;

  String get name => json['name']! as String;
  double _n(String key) => (json[key]! as num).toDouble();
  double get label => _n('label');
  double get childPadding => _n('childPadding');
  double get indent => _n('indent');
  double get endIndent => _n('endIndent');
  CoreDividerChildAlignment get alignment =>
      CoreDividerChildAlignment.values.byName(json['alignment']! as String);
  double get width => _n('width');
}

/// The element id of a probe: the case's position in the table and the
/// direction it is laid out in.
String _id(int index, String direction) => 'divider-$index-$direction';

/// One probe — the production `Divider` in a box of the case's length, in the
/// case's text direction.
Component _probe(int index, _Case c, String direction, double crossExtent) {
  final labelBox = div(
    const [],
    attributes: const {'data-label': ''},
    styles: Styles(
      raw: {
        'width': '${c.horizontal ? c.label : crossExtent}px',
        'height': '${c.horizontal ? crossExtent : c.label}px',
      },
    ),
  );
  final divider = Divider(
    id: _id(index, direction),
    orientation: c.horizontal ? .horizontal : .vertical,
    dividerStyle: CoreDividerStyle(
      indent: c.indent,
      endIndent: c.endIndent,
      childAlignment: c.alignment,
      childPadding: CoreEdgeInsets.symmetric(horizontal: c.childPadding),
    ),
    child: labelBox,
  );

  return div(
    [divider],
    attributes: {'dir': direction, 'data-probe': _id(index, direction)},
    styles: Styles(
      raw: {
        if (c.horizontal) 'width': '${c.box}px',
        // A vertical divider fills its parent's height, so the parent states
        // it.
        if (!c.horizontal) 'height': '${c.box}px',
        if (!c.horizontal) 'width': '${crossExtent * 2}px',
      },
    ),
  );
}

/// The element id of an intrinsic probe: the row's position in the table.
String _intrinsicId(int index) => 'divider-intrinsic-$index';

/// One intrinsic probe — the production `Divider` in a parent that is as wide
/// as its content (`inline-block`), which gives it no length of its own to
/// share.
Component _intrinsicProbe(int index, _Intrinsic row, double crossExtent) {
  final divider = Divider(
    id: _intrinsicId(index),
    dividerStyle: CoreDividerStyle(
      indent: row.indent,
      endIndent: row.endIndent,
      childAlignment: row.alignment,
      childPadding: CoreEdgeInsets.symmetric(horizontal: row.childPadding),
    ),
    child: div(
      const [],
      styles: Styles(
        raw: {'width': '${row.label}px', 'height': '${crossExtent}px'},
      ),
    ),
  );

  return div([
    div(
      [divider],
      attributes: {'data-intrinsic': _intrinsicId(index)},
      styles: const Styles(raw: {'display': 'inline-block'}),
    ),
  ]);
}

/// For every probe: the divider's own box, the label's and the rects of the
/// first and last child of the divider — the two line segments, with the
/// label's wrapper between them.
const String _kMeasureJs = '''
() => {
  const rect = (el) => {
    const r = el.getBoundingClientRect();
    return {left: r.left, right: r.right, top: r.top, bottom: r.bottom};
  };
  const out = {};
  for (const probe of document.querySelectorAll('[data-probe]')) {
    const root = probe.firstElementChild;
    const kids = [...root.children];
    out[probe.getAttribute('data-probe')] = {
      box: rect(root),
      label: rect(root.querySelector('[data-label]')),
      segmentCount: kids.length,
      lines: [rect(kids[0]), rect(kids[kids.length - 1])],
    };
  }
  // The dividers whose parent is as wide as its content: their own width.
  for (const host of document.querySelectorAll('[data-intrinsic]')) {
    out[host.getAttribute('data-intrinsic')] = {
      box: rect(host.firstElementChild),
    };
  }
  return JSON.stringify(out);
}
''';

Map<String, double> _rect(Object? json) => {
  for (final e in (json! as Map<String, Object?>).entries)
    e.key: (e.value! as num).toDouble(),
};

/// [rect]'s extent along the divider's main axis, from the box's start edge in
/// reading order.
_Span _fromStart(
  Map<String, double> rect,
  Map<String, double> box, {
  required bool horizontal,
  required String direction,
}) {
  if (!horizontal) {
    return (
      start: rect['top']! - box['top']!,
      end: rect['bottom']! - box['top']!,
    );
  }

  return direction == 'ltr'
      ? (
          start: rect['left']! - box['left']!,
          end: rect['right']! - box['left']!,
        )
      : (
          start: box['right']! - rect['right']!,
          end: box['right']! - rect['left']!,
        );
}

void main() {
  final chromePath = _systemChromePath();
  final doc =
      jsonDecode(File(kDividerLabelVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = [
    for (final c in (doc['cases']! as List).cast<Map<String, Object?>>())
      _Case(c),
  ];
  final directions = (doc['directions']! as List).cast<String>();
  final tolerance = ((doc['tolerance']! as Map)['web']! as num).toDouble();
  final crossExtent = (doc['crossExtent']! as num).toDouble();
  final intrinsic = [
    for (final row in (doc['intrinsic']! as List).cast<Map<String, Object?>>())
      _Intrinsic(row),
  ];

  late pptr.Browser browser;
  late Directory workDir;
  late Map<String, Object?> measured;

  setUpAll(() async {
    if (chromePath == null) return;
    final body = await renderComponentBodyHtml(
      Theme.defaults(
        child: div([
          for (final (i, c) in cases.indexed)
            for (final direction in c.directions ?? directions)
              _probe(i, c, direction, crossExtent),
          for (final (i, row) in intrinsic.indexed)
            _intrinsicProbe(i, row, crossExtent),
        ]),
      ),
    );
    final html = buildOfflineTailwindHarnessHtml(
      bodyHtml: body,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>',
    );
    workDir = Directory.systemTemp.createTempSync('divider-label-probe-');
    final file = File(p.join(workDir.path, 'probe.html'))
      ..writeAsStringSync(html);
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
    final page = await browser.newPage();
    try {
      await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
      measured =
          jsonDecode(await page.evaluate<String>(_kMeasureJs))
              as Map<String, Object?>;
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

  test('the vector table is not empty', () {
    expect(cases, isNotEmpty);
    expect(directions, ['ltr', 'rtl']);
  });

  group('a labelled Divider in Chrome against the shared vectors', () {
    for (final (i, c) in cases.indexed) {
      for (final direction in c.directions ?? directions) {
        test('${c.name} ($direction)', () {
          final probe = measured[_id(i, direction)]! as Map<String, Object?>;
          final box = _rect(probe['box']);
          final span = _fromStart(
            box,
            box,
            horizontal: c.horizontal,
            direction: direction,
          );
          expect(
            span.end - span.start,
            closeTo(c.box, tolerance),
            reason: 'the divider keeps the length of its box',
          );
          expect(probe['segmentCount'], 3, reason: 'segment, label, segment');

          final label = _fromStart(
            _rect(probe['label']),
            box,
            horizontal: c.horizontal,
            direction: direction,
          );
          expect(
            (label.start + label.end) / 2,
            closeTo(c.labelCentre, tolerance),
            reason: 'the label centre, from the start edge',
          );
          expect(
            label.end - label.start,
            closeTo(c.label, tolerance),
            reason: 'the label keeps its own length',
          );

          final expected = c.lines;
          final lines = (probe['lines']! as List).cast<Object?>();
          for (var s = 0; s < 2; s++) {
            final line = _fromStart(
              _rect(lines[s]),
              box,
              horizontal: c.horizontal,
              direction: direction,
            );
            final lineRect = _rect(lines[s]);
            final labelRect = _rect(probe['label']);
            double across(Map<String, double> rect) => c.horizontal
                ? (rect['top']! + rect['bottom']!) / 2
                : (rect['left']! + rect['right']!) / 2;
            expect(
              across(lineRect),
              closeTo(across(labelRect), tolerance),
              reason: 'segment $s is centred across the axis on the label',
            );
            final want = expected[s];
            if (want == null) {
              expect(
                line.end - line.start,
                closeTo(0, tolerance),
                reason: 'segment $s has no length',
              );
            } else {
              expect(
                line.start,
                closeTo(want.start, tolerance),
                reason: 'segment $s starts',
              );
              expect(
                line.end,
                closeTo(want.end, tolerance),
                reason: 'segment $s ends',
              );
            }
          }
        });
      }
    }
  }, skip: skip);

  group('a labelled Divider whose parent takes its width from its content '
      'in Chrome', () {
    // A shrink-to-fit parent gives the box no length to share, so each
    // weighted segment is as long as the larger inset allows: the box holds
    // the larger inset on both sides and the label stays centred, which is
    // the width Flutter's `IntrinsicWidth` gives the same divider.
    for (final (i, row) in intrinsic.indexed) {
      test(row.name, () {
        final probe = measured[_intrinsicId(i)]! as Map<String, Object?>;
        final box = _rect(probe['box']);

        expect(
          box['right']! - box['left']!,
          closeTo(row.width, tolerance),
          reason: 'the divider is as wide as its content makes it',
        );
      });
    }
  }, skip: skip);
}

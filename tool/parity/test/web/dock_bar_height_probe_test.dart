// A Dock bar, rendered — how tall a real Chrome with the vendored Tailwind
// makes the bar of the component's own server output.
//
// The Web resolver's unit tests read the markup it emits. That proves the
// declarations, not the layout, and the claim lives in the layout: the bar is
// `min-height` over a flex row, so it is exactly the Core minimum while its
// items fit and as tall as they ask once they do not, with the items centred
// in it either way and the active pill inside it. Flutter lays the same bar out
// from the same inputs; the vector table `dock_bar_height_vectors.json` is what
// that layout comes to, and `dock_bar_height_test.dart` in coui_flutter
// measures the widget tree against it. This file measures the DOM against it,
// so a layout change on one platform fails the other.
//
// Every number is a rect the browser laid out — the bar's, the items', the
// labels', the icons' and the pill's.
//
// The pages mount the docs site's own reset (`docsContentTheme().styles`, which
// the parity captures mount too): border-box sizing and a solid border style,
// which a page that ships its own reset gives coui_web and which the hairline
// needs to be drawn at all. A last page mounts none, as a consumer page without
// a reset has none, and holds the bar at its Core minimum there too. Two more
// pages set a density on the document the way the app's density scope does, and
// hold the room kept for the pill to the density-bent value it is built from.
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

/// The table shared with the Core reference test and the Flutter widget test.
const String kDockBarHeightVectorsPath =
    'packages/coui_core/test/fixtures/dock_bar_height_vectors.json';

/// The width of every probe's host, in CSS px.
const double kProbeWidth = 320;

/// Label font sizes in CSS px, as a label overlay: the role's own 12, and the
/// sizes a 200% and a 300% text-size setting makes of it. The bar around them
/// is the same Core minimum.
const List<double> kLabelFontSizes = [12, 24, 36];

/// The root font size of the zoomed page, in CSS px — a browser's 200% text
/// size, which every `rem` length follows.
const double kZoomedRootFontSize = 32;

/// The rows of the table the page with no reset renders: the default md bar
/// that fits its minimum, and two md rows that grow.
const List<int> kBareRows = [2, 6, 7];

/// The rows of the table the density pages render: the default md bar that
/// fits its minimum, an md row that grows, and the row whose plate reaches
/// unequally past the padding — the room is the larger side, bent through the
/// density.
const List<int> kDensityRows = [2, 7, 13];

/// The densities the pages are rendered under, besides the standard one.
const List<CoreDensity> kDensities = [
  CoreDensity.compact,
  CoreDensity.spacious,
];

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

/// One row of the table.
class _Case {
  _Case(this.json);

  final Map<String, Object?> json;

  String get name => json['name']! as String;
  CoreDockSize get size => CoreDockSize.values.byName(json['size']! as String);
  double get iconSize => (json['iconSize']! as num).toDouble();
  double get bar => (json['bar']! as num).toDouble();

  CoreEdgeInsets? _vertical(String key) {
    final padding = json[key] as Map<String, Object?>?;
    if (padding == null) return null;

    return CoreEdgeInsets.only(
      top: (padding['top']! as num).toDouble(),
      bottom: (padding['bottom']! as num).toDouble(),
    );
  }

  CoreEdgeInsets? get indicatorPadding => _vertical('indicatorPadding');

  /// The bar padding the row states — its sides kept at the size's own.
  CoreEdgeInsets? get padding {
    final vertical = _vertical('padding');
    if (vertical == null) return null;
    final own = CoreDockStyle.defaultsBySize[size]!.padding!;

    return CoreEdgeInsets.fromLTRB(
      own.left,
      vertical.top,
      own.right,
      vertical.bottom,
    );
  }

  /// The room the bar keeps above (and below) its row for this row's inputs,
  /// bent by [density].
  double rowInset({CoreDensity? density}) {
    final own = CoreDockStyle.defaultsBySize[size]!;
    final inset = CoreDockStyle.rowInsetFor(
      (padding ?? own.padding!).top,
      indicatorPadding ?? own.indicatorPadding!,
    );

    return density == null ? inset : density.space(inset);
  }
}

String _caseId(int index, [String page = 'plain', bool tappable = true]) =>
    'dock-row-$page${tappable ? '' : '-inert'}-$index';

String _labelId(int index, String page) => 'dock-label-$page-$index';

/// The dock of a table row: the production `Dock`, three items with an icon
/// each and no label, so an item is as tall as its icon and no number depends
/// on a font.
Component _caseProbe(
  int index,
  _Case c, {
  String page = 'plain',
  bool tappable = true,
}) {
  final dock = Dock(
    id: _caseId(index, page, tappable),
    size: c.size,
    dockStyle: CoreDockStyle(
      padding: c.padding,
      indicatorPadding: c.indicatorPadding,
      iconStyle: CoreIconStyle(size: c.iconSize),
    ),
    items: [
      for (var i = 0; i < 3; i++)
        CoreDockItemData<Component>(
          icon: const Icon(LucideIcons.house),
          isActive: i == 0,
          onPressed: tappable ? () {} : null,
        ),
    ],
  );

  return div(
    [dock],
    attributes: {'data-probe': _caseId(index, page, tappable)},
    styles: const Styles(raw: {'width': '${kProbeWidth}px'}),
  );
}

/// A bar of labels at [fontSize] — the label grown the way a text-size
/// setting grows it, while the icon and the Core minimum stay put.
Component _labelProbe(String page, int index, double fontSize) {
  final dock = Dock(
    id: _labelId(index, page),
    dockStyle: CoreDockStyle(
      labelTextStyle: CoreTextStyle(fontSize: fontSize),
    ),
    items: [
      for (final (i, label) in ['Home', 'Search', 'Profile'].indexed)
        CoreDockItemData<Component>(
          icon: const Icon(LucideIcons.house),
          label: label,
          isActive: i == 0,
          onPressed: () {},
        ),
    ],
  );

  return div(
    [dock],
    attributes: {'data-probe': _labelId(index, page)},
    // Wide enough for the labels side by side at the largest size: the only
    // thing this probe can overflow is the bar's height.
    styles: const Styles(raw: {'width': '720px'}),
  );
}

/// For every probe: the bar's own box, its top border, and for each item the
/// item's box, its icon row, its label and the plate inside the icon row.
const String _kMeasureJs = '''
() => {
  const rect = (el) => {
    if (!el) return null;
    const r = el.getBoundingClientRect();
    return {left: r.left, right: r.right, top: r.top, bottom: r.bottom};
  };
  const out = {};
  for (const host of document.querySelectorAll('[data-probe]')) {
    const bar = host.firstElementChild;
    const items = [...bar.querySelectorAll('.flex-col')].map((item) => {
      const kids = [...item.children];
      const icon = kids.find((k) => k.style.display === 'inline-flex');
      return {
        box: rect(item),
        clickable: rect(item.closest('[role="button"]')),
        icon: rect(icon),
        label: rect(kids.find((k) => k.textContent.trim().length > 0)),
        pill: rect(icon && icon.querySelector('[aria-hidden="true"]')),
      };
    });
    out[host.getAttribute('data-probe')] = {
      bar: rect(bar),
      borderTop: parseFloat(getComputedStyle(bar).borderTopWidth),
      minHeight: parseFloat(getComputedStyle(bar).minHeight),
      items: items,
    };
  }
  return JSON.stringify(out);
}
''';

typedef _Rect = ({double left, double right, double top, double bottom});

_Rect? _rect(Object? json) {
  if (json == null) return null;
  final map = json as Map<String, Object?>;
  double n(String key) => (map[key]! as num).toDouble();

  return (
    left: n('left'),
    right: n('right'),
    top: n('top'),
    bottom: n('bottom'),
  );
}

double _height(_Rect r) => r.bottom - r.top;

double _centre(_Rect r) => (r.top + r.bottom) / 2;

/// One measured probe.
class _Probe {
  _Probe(Map<String, Object?> json)
    : bar = _rect(json['bar'])!,
      borderTop = (json['borderTop']! as num).toDouble(),
      minHeight = (json['minHeight']! as num).toDouble(),
      items = [
        for (final item
            in (json['items']! as List).cast<Map<String, Object?>>())
          (
            box: _rect(item['box'])!,
            clickable: _rect(item['clickable']),
            icon: _rect(item['icon']),
            label: _rect(item['label']),
            pill: _rect(item['pill']),
          ),
      ];

  final _Rect bar;
  final double borderTop;
  final double minHeight;
  final List<
    ({_Rect box, _Rect? clickable, _Rect? icon, _Rect? label, _Rect? pill})
  >
  items;
}

void main() {
  final chromePath = _systemChromePath();
  final doc =
      jsonDecode(File(kDockBarHeightVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = [
    for (final c in (doc['cases']! as List).cast<Map<String, Object?>>())
      _Case(c),
  ];
  final tolerance = ((doc['tolerance']! as Map)['web']! as num).toDouble();

  late pptr.Browser browser;
  late Directory workDir;
  late Map<String, _Probe> measured;

  Future<Map<String, Object?>> measure(
    String name,
    String bodyHtml, {
    String additionalHeadHtml = '',
    CoreDensity? density,
  }) async {
    final html = buildOfflineTailwindHarnessHtml(
      bodyHtml: bodyHtml,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>$additionalHeadHtml',
    );
    final file = File(p.join(workDir.path, '$name.html'))
      ..writeAsStringSync(html);
    final page = await browser.newPage();
    try {
      await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
      if (density != null) {
        // The attribute the stylesheet's density rules key on, set on the
        // document after load as the app's density scope sets it.
        await page.evaluate<void>(
          "() => document.documentElement.setAttribute('data-coui-density', "
          "'${density.name}')",
        );
        await page.evaluate<void>(
          '() => new Promise(resolve => requestAnimationFrame(() => '
          'requestAnimationFrame(() => resolve())))',
        );
      }

      return jsonDecode(await page.evaluate<String>(_kMeasureJs))
          as Map<String, Object?>;
    } finally {
      await page.close();
    }
  }

  setUpAll(() async {
    if (chromePath == null) return;
    workDir = Directory.systemTemp.createTempSync('dock-bar-height-probe-');
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
    measured = {};

    /// The body of a page: the site's reset, unless the page is bare, and the
    /// probes under the default theme.
    Future<String> body(List<Component> probes, {bool reset = true}) =>
        renderComponentBodyHtml(
          Component.fragment([
            if (reset) Style(styles: docsContentTheme().styles),
            Theme.defaults(child: div(probes)),
          ]),
        );

    // Page one: the table, and the labels at three sizes, at the browser's
    // own 16px root.
    final plain = await measure(
      'plain',
      await body([
        for (final (i, c) in cases.indexed) ...[
          _caseProbe(i, c),
          _caseProbe(i, c, tappable: false),
        ],
        for (final (i, size) in kLabelFontSizes.indexed)
          _labelProbe('plain', i, size),
      ]),
    );
    // Page two: the labels at the role's own size under a 200% root font
    // size, which every `rem` length — the minimum included — follows.
    final zoomed = await measure(
      'zoomed',
      await body([_labelProbe('zoomed', 0, 12)]),
      additionalHeadHtml:
          '<style>html{font-size:${kZoomedRootFontSize}px}</style>',
    );
    // Page three: no reset at all — content-box sizing and no preflight — with
    // the table's first and its first growing rows.
    final bare = await measure(
      'bare',
      await body([
        for (final i in kBareRows) _caseProbe(i, cases[i], page: 'bare'),
      ], reset: false),
    );
    // Pages four and five: the same rows under each density.
    final dense = <MapEntry<String, Object?>>[];
    for (final density in kDensities) {
      final page = await measure(
        'density-${density.name}',
        await body([
          for (final i in kDensityRows) ...[
            _caseProbe(i, cases[i], page: density.name),
            _caseProbe(i, cases[i], page: density.name, tappable: false),
          ],
        ]),
        density: density,
      );
      dense.addAll(page.entries);
    }
    for (final entry in [
      ...plain.entries,
      ...zoomed.entries,
      ...bare.entries,
      ...dense,
    ]) {
      measured[entry.key] = _Probe(entry.value! as Map<String, Object?>);
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
  });

  group('a Dock bar in Chrome against the shared vectors', () {
    for (final (i, c) in cases.indexed) {
      // A tappable item is the flex item through its `Clickable`'s root and an
      // inert one through its own wrapper — the margin has two carriers, and
      // the bar is the same either way.
      for (final tappable in [true, false]) {
        test('${c.name}${tappable ? '' : ' (items inert)'}', () {
          final probe = measured[_caseId(i, 'plain', tappable)]!;

          expect(probe.items, hasLength(3), reason: 'one box per item');
          expect(
            _height(probe.bar),
            closeTo(c.bar, tolerance),
            reason:
                'the bar is as tall as its row asks, never under the minimum',
          );
          expect(
            probe.borderTop,
            (doc['border']! as num).toDouble(),
            reason: 'the bar draws the line the table counts',
          );
          // Centred in the bar — the line is on both edges — in the minimum
          // state and once the bar has grown.
          final centre = (probe.bar.top + probe.bar.bottom) / 2;
          for (final item in probe.items) {
            expect(_centre(item.box), closeTo(centre, tolerance));
          }
          // The icon is the item, and the plate — the icon row widened by the
          // plate's padding — stays inside the bar.
          for (final item in probe.items) {
            expect(_height(item.box), closeTo(c.iconSize, tolerance));
            // The `Clickable` — whose border box carries the focus ring and
            // the hit area — is the item's box, not the item plus the room
            // kept for the pill: that room is margin, outside it.
            final clickable = item.clickable;
            if (tappable) {
              expect(clickable, isNotNull);
              expect(clickable!.top, closeTo(item.box.top, tolerance));
              expect(clickable.bottom, closeTo(item.box.bottom, tolerance));
            } else {
              expect(clickable, isNull);
            }
          }
          final pill = probe.items.first.pill!;
          expect(pill.top, greaterThanOrEqualTo(probe.bar.top - tolerance));
          expect(pill.bottom, lessThanOrEqualTo(probe.bar.bottom + tolerance));
        });
      }
    }
  }, skip: skip);

  group('a Dock bar with the label grown, in Chrome', () {
    for (final (i, fontSize) in kLabelFontSizes.indexed) {
      test('labels at ${fontSize.toInt()}px', () {
        final probe = measured[_labelId(i, 'plain')]!;
        expect(probe.items, hasLength(3), reason: 'one box per item');
        // md: 10 above and below, the line on both edges.
        const rowInset = 10.0;
        final tallest = probe.items
            .map((item) => _height(item.box))
            .reduce((one, other) => one > other ? one : other);
        final asked = tallest + 2 * rowInset + 2 * probe.borderTop;

        // The Core minimum, as the page computes it, is the one Core states.
        expect(probe.minHeight, 64);
        expect(
          _height(probe.bar),
          closeTo(asked > 64 ? asked : 64, tolerance),
          reason: 'as tall as the row asks, never under the minimum',
        );

        // Nothing leaves the bar: not the icon, not the label, not the pill.
        for (final item in probe.items) {
          for (final inner in [item.icon!, item.label!, item.box]) {
            expect(inner.top, greaterThanOrEqualTo(probe.bar.top - tolerance));
            expect(
              inner.bottom,
              lessThanOrEqualTo(probe.bar.bottom + tolerance),
            );
          }
        }
        final pill = probe.items.first.pill!;
        expect(pill.top, greaterThanOrEqualTo(probe.bar.top - tolerance));
        expect(pill.bottom, lessThanOrEqualTo(probe.bar.bottom + tolerance));

        final centre = (probe.bar.top + probe.bar.bottom) / 2;
        for (final item in probe.items) {
          expect(_centre(item.box), closeTo(centre, tolerance));
        }
      });
    }

    test('the bar grows with the label', () {
      double barAt(int i) => _height(measured[_labelId(i, 'plain')]!.bar);

      // 12px: 24 icon, 4 gap and a 17px line, 10 above and below and the line
      // on both edges — 67, past the Core minimum of 64.
      expect(barAt(0), closeTo(67, tolerance));
      // 24px and 36px: a bar that grew, and by more at the larger size.
      expect(barAt(1), greaterThan(barAt(0)));
      expect(barAt(2), greaterThan(barAt(1)));
    });
  }, skip: skip);

  group('a Dock bar on a page with no reset, in Chrome', () {
    // Content-box sizing and no preflight: `min-height` would then be the
    // content box's, and root padding would be added on top of it. The room
    // above and below the row rides the items' margins instead, so the bar at
    // its minimum is the Core minimum here too, and a grown bar is the row
    // plus its margins plus the line on both edges. The bar states the line's
    // style itself (inline `border-style: solid`), so a page with no reset
    // draws it just as a reset page does.
    for (final i in kBareRows) {
      test(cases[i].name, () {
        final probe = measured[_caseId(i, 'bare')]!;
        final c = cases[i];
        final minimum = CoreDockStyle.defaultsBySize[c.size]!.height!;
        final asked = c.iconSize + 2 * c.rowInset() + 2 * probe.borderTop;

        expect(
          probe.borderTop,
          (doc['border']! as num).toDouble(),
          reason: 'the bar draws its line whatever the page resets',
        );
        expect(
          _height(probe.bar),
          closeTo(asked > minimum ? asked : minimum, tolerance),
        );
      });
    }
  }, skip: skip);

  group('a Dock bar under a density, in Chrome', () {
    for (final density in kDensities) {
      for (final i in kDensityRows) {
        final c = cases[i];
        final unequal = c.indicatorPadding == null
            ? ''
            : ', the pill padded unequally';
        final name =
            '${density.name}: ${c.size.name}, a ${c.iconSize.toInt()}px icon'
            '$unequal';
        for (final tappable in [true, false]) {
          test(
            '$name${tappable ? '' : ' (items inert)'}',
            () {
              final probe = measured[_caseId(i, density.name, tappable)]!;
              final minimum = CoreDockStyle.defaultsBySize[c.size]!.height!;
              // The room above and below is the padding or the plate's reach,
              // whichever is larger, bent through the density.
              final asked =
                  c.iconSize +
                  2 * c.rowInset(density: density) +
                  2 * (doc['border']! as num);

              expect(
                probe.minHeight,
                minimum,
                reason: 'the minimum is a Core value a density does not bend',
              );
              expect(
                _height(probe.bar),
                closeTo(asked > minimum ? asked : minimum, tolerance),
              );
              if (asked > minimum) {
                // The bar that grew is the one the density moved: against the
                // standard density's bar, shorter when compact and taller
                // when spacious.
                expect(
                  _height(probe.bar),
                  density == CoreDensity.compact
                      ? lessThan(c.bar)
                      : greaterThan(c.bar),
                  reason: 'the density really moved the room around the row',
                );
              }

              // The plate stays inside the bar whatever the density.
              final pill = probe.items.first.pill!;
              expect(
                pill.top,
                greaterThanOrEqualTo(probe.bar.top - tolerance),
              );
              expect(
                pill.bottom,
                lessThanOrEqualTo(probe.bar.bottom + tolerance),
              );
            },
          );
        }
      }
    }
  }, skip: skip);

  group('a Dock bar under a 200% root font size, in Chrome', () {
    test('its minimum and its content grow together, and nothing clips', () {
      final probe = measured[_labelId(0, 'zoomed')]!;

      // The minimum is a `rem` length: twice the Core height at twice the
      // root font size, and the items, the gap, the padding and the label
      // follow it — only the line around the bar stays a pixel.
      expect(
        probe.minHeight,
        closeTo(64 * kZoomedRootFontSize / 16, tolerance),
      );
      expect(
        _height(probe.bar),
        greaterThanOrEqualTo(probe.minHeight - tolerance),
        reason: 'everything scaled together, never under the minimum',
      );
      for (final item in probe.items) {
        for (final inner in [item.icon!, item.label!, item.box]) {
          expect(inner.top, greaterThanOrEqualTo(probe.bar.top - tolerance));
          expect(inner.bottom, lessThanOrEqualTo(probe.bar.bottom + tolerance));
        }
      }
    });
  }, skip: skip);
}

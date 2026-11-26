// Dialog actions stretched (`CoreDialogActionsLayout.stretch`) — the Chrome
// half of the shared stretch vectors.
//
// The Web states the stretched row in CSS and lets the browser place the
// actions: the footer stays a wrapping flex row, and every action sits in a
// cell that starts at an equal share of the row (`flex-basis`), grows into
// what its line leaves and never goes narrower than its action
// (`min-width: fit-content`). Flutter has no such layout and places the
// actions with `CoreDialogActionsStretch.place`. The two agree only if that
// rule is the one Chrome's flex layout follows, so this file lays every
// vector out in Chrome — the footer and cell chrome the resolver emits, the
// footer exactly the vector's width — and checks where each action landed
// against the table the Core and Flutter tests read, in both directions.
//
// Each action is a stand-in with the table's shape: fixed-size parts laid
// side by side that wrap between them, so its narrowest width is its widest
// part and its natural width the sum of its parts. Every part is the
// action's own `partHeight` when the table states one, the table's
// `partHeight` otherwise.
//
// The table's `cells` are the CSS answer and the one this file checks.
// `flutterCells`, where a case carries it, is what Flutter draws instead
// (Flutter never lays an action out wider than its row) and is not Chrome's
// to answer.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/normalize/css_value_parsers.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

/// The table shared with the Core placement test and the Flutter actions
/// layout test.
const String kDialogActionsStretchVectorsPath =
    'packages/coui_core/test/fixtures/dialog_actions_stretch_vectors.json';

/// One layout unit (Chrome lays boxes out in 1/64 px) plus the table's own
/// rounding — the table writes thirds to six places.
const double _kTolerance = 1 / 64 + 1e-3;

/// Room around every footer, so an action that overflows its row's start
/// edge stays on the page.
const double _kPagePaddingPx = 64;

/// Where the probe looks for Chrome, in order: `CHROME_EXECUTABLE` when it is
/// set — CI's web-selection job sets it to the runner's browser — then the
/// system installs `browser_launch_test.dart` looks in. A system Chrome
/// avoids Puppeteer's own Chromium download, so the test needs no network.
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

/// One stand-in action: its parts' widths and how tall every part is.
typedef _StandIn = ({List<num> parts, num partHeight});

/// For every `[data-case]` footer: its box, the computed declarations the
/// resolver's chrome is meant to produce, and each action's box.
const String _kMeasureJs = '''
() => {
  const box = (el) => {
    const r = el.getBoundingClientRect();
    return {left: r.left, right: r.right, top: r.top, bottom: r.bottom,
      width: r.width};
  };
  const out = {};
  for (const footer of document.querySelectorAll('[data-case]')) {
    const fs = getComputedStyle(footer);
    const cs = getComputedStyle(footer.firstElementChild);
    out[footer.getAttribute('data-case')] = {
      footer: box(footer),
      display: fs.display,
      flexWrap: fs.flexWrap,
      justifyContent: fs.justifyContent,
      columnGap: fs.columnGap,
      rowGap: fs.rowGap,
      direction: fs.direction,
      cell: {
        display: cs.display,
        flexDirection: cs.flexDirection,
        flexGrow: cs.flexGrow,
        minWidth: cs.minWidth,
      },
      actions: [...footer.children].map((cell) => box(cell.firstElementChild)),
    };
  }
  return JSON.stringify(out);
}
''';

/// True once the vendored Tailwind has written its stylesheet — it does so
/// after it scans the page, and a footer that is a flex row is the sign the
/// classes have arrived.
const String _kStylesheetArrivedJs =
    "() => getComputedStyle(document.querySelector('[data-case]')).display "
    "=== 'flex'";

/// A stand-in action — fixed-size parts that wrap between them, each its
/// `partHeight` tall, inline like the `Button` it stands in for.
Component _action(_StandIn action) => div(
  [
    for (final width in action.parts)
      div(
        const [],
        styles: Styles(
          raw: {
            'flex': 'none',
            'width': '${width}px',
            'height': '${action.partHeight}px',
          },
        ),
      ),
  ],
  styles: const Styles(raw: {'display': 'inline-flex', 'flex-wrap': 'wrap'}),
);

/// How many rows [parts] take laid side by side and wrapping between them
/// in [width] — a part starts a row when the one it follows leaves it too
/// little room, and a part wider than [width] keeps a row to itself.
int _rows(List<num> parts, double width) {
  var rows = 1;
  var used = 0.0;
  for (final part in parts) {
    if (used > 0 && used + part > width + _kTolerance) {
      rows += 1;
      used = 0;
    }
    used += part;
  }

  return rows;
}

/// One vector's footer — the chrome `resolveDialog` emits for a stretched
/// row of [actions], the footer's content box exactly [width] wide.
class _Footer extends StatelessComponent {
  const _Footer({
    required this.index,
    required this.width,
    required this.actions,
    required this.dialogStyle,
  });

  final int index;
  final num width;
  final List<_StandIn> actions;
  final CoreDialogStyle dialogStyle;

  @override
  Component build(BuildContext context) {
    final resolved = resolveDialog(
      context,
      actionCount: actions.length,
      dialogStyle: dialogStyle,
    );
    final cell = resolved.actionCell!;

    return div(
      [
        for (final action in actions)
          div(
            [_action(action)],
            classes: cell.className,
            styles: cell.inlineStyles,
          ),
      ],
      classes: resolved.footer.className,
      styles: Styles.combine([
        ?resolved.footer.inlineStyles,
        Styles(raw: {'width': '${width}px'}),
      ]),
      attributes: {'data-case': '$index'},
    );
  }
}

double _n(Map<String, Object?> box, String key) =>
    (box[key]! as num).toDouble();

bool _near(double measured, double expected) =>
    (measured - expected).abs() <= _kTolerance;

void main() {
  final chromeCandidates = _chromeCandidates();
  final chromePath = chromeCandidates
      .where((candidate) => File(candidate).existsSync())
      .firstOrNull;
  final doc =
      jsonDecode(File(kDialogActionsStretchVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final spacing = (doc['spacing']! as num).toDouble();
  final runSpacing = (doc['runSpacing']! as num).toDouble();
  final partHeight = doc['partHeight']! as num;
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();
  // Every case's stand-ins, an action's own partHeight over the table's.
  final standIns = [
    for (final c in cases)
      [
        for (final action
            in (c['actions']! as List).cast<Map<String, Object?>>())
          (
            parts: (action['parts']! as List).cast<num>(),
            partHeight: action['partHeight'] as num? ?? partHeight,
          ),
      ],
  ];
  final dialogStyle = CoreDialogStyle(
    actionsLayout: CoreDialogActionsLayout.stretch,
    actionSpacing: spacing,
    actionRunSpacing: runSpacing,
  );

  late pptr.Browser browser;
  late Directory workDir;
  late String bodyHtml;

  setUpAll(() async {
    if (chromePath == null) return;
    bodyHtml = await renderComponentBodyHtml(
      Theme.defaults(
        child: div(
          [
            for (final (i, c) in cases.indexed)
              div(
                [
                  _Footer(
                    index: i,
                    width: c['width']! as num,
                    actions: standIns[i],
                    dialogStyle: dialogStyle,
                  ),
                ],
                styles: const Styles(
                  raw: {'margin-bottom': '${_kPagePaddingPx}px'},
                ),
              ),
          ],
          styles: const Styles(raw: {'padding': '${_kPagePaddingPx}px'}),
        ),
      ),
    );
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
    workDir = Directory.systemTemp.createTempSync('dialog-stretch-probe-');
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    workDir.deleteSync(recursive: true);
  });

  /// Lays every vector out in Chrome under [dir] and returns what each
  /// footer measured.
  Future<Map<String, Object?>> measure(String dir) async {
    final html = buildOfflineTailwindHarnessHtml(
      bodyHtml: bodyHtml,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>',
    ).replaceFirst('<html ', '<html dir="$dir" ');
    final file = File(p.join(workDir.path, 'dialog_stretch_$dir.html'))
      ..writeAsStringSync(html);

    final page = await browser.newPage();
    try {
      await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
      await page.waitForFunction(_kStylesheetArrivedJs);

      return jsonDecode(await page.evaluate<String>(_kMeasureJs))
          as Map<String, Object?>;
    } finally {
      await page.close();
    }
  }

  /// Every way the [dir] layout disagrees with the table — all at once, since
  /// one case's failure says little about which part of the rule is off.
  List<String> disagreements(Map<String, Object?> measured, String dir) {
    final out = <String>[];
    for (final (i, c) in cases.indexed) {
      final name = '${c['name']} [$dir]';
      final m = measured['$i']! as Map<String, Object?>;
      final footer = m['footer']! as Map<String, Object?>;
      final cell = m['cell']! as Map<String, Object?>;
      final width = (c['width']! as num).toDouble();

      // The chrome the resolver emits, as Chrome computed it — without it
      // the boxes below would measure some other layout.
      final declared = <String, Object?>{
        'display': m['display'],
        'flex-wrap': m['flexWrap'],
        'justify-content': parseCssFlexAlignment(
          m['justifyContent']! as String,
        ),
        'column-gap': m['columnGap'],
        'row-gap': m['rowGap'],
        'direction': m['direction'],
        'cell display': cell['display'],
        'cell flex-direction': cell['flexDirection'],
        'cell flex-grow': cell['flexGrow'],
        'cell min-width': cell['minWidth'],
      };
      final expectedDeclared = <String, Object?>{
        'display': 'flex',
        'flex-wrap': 'wrap',
        'justify-content': 'flex-end',
        'column-gap': '${spacing.toInt()}px',
        'row-gap': '${runSpacing.toInt()}px',
        'direction': dir,
        'cell display': 'flex',
        'cell flex-direction': 'column',
        'cell flex-grow': '1',
        'cell min-width': 'fit-content',
      };
      for (final MapEntry(:key, :value) in expectedDeclared.entries) {
        if (declared[key] != value) {
          out.add('$name: $key is ${declared[key]}, expected $value');
        }
      }
      if (!_near(_n(footer, 'width'), width)) {
        out.add('$name: footer is ${_n(footer, 'width')}px, expected $width');
      }

      final actions = (m['actions']! as List).cast<Map<String, Object?>>();
      // `cells`, never `flutterCells` — Chrome answers for CSS.
      final cells = (c['cells']! as List).cast<Map<String, Object?>>();
      if (actions.length != cells.length) {
        out.add('$name: ${actions.length} actions, expected ${cells.length}');
        continue;
      }

      // Height: as many part rows as the action's parts take in the width
      // it landed at, each the partHeight the table states — read from the
      // table, not from the stand-ins, so a stand-in built to some other
      // shape fails here instead of the line checks below measuring it.
      final tableActions = (c['actions']! as List).cast<Map<String, Object?>>();
      for (final (j, box) in actions.indexed) {
        final stated = tableActions[j];
        final height = _n(box, 'bottom') - _n(box, 'top');
        final expectedHeight =
            _rows((stated['parts']! as List).cast<num>(), _n(box, 'width')) *
            (stated['partHeight'] as num? ?? partHeight);
        if (!_near(height, expectedHeight.toDouble())) {
          out.add(
            '$name: action $j is ${height}px tall, expected $expectedHeight',
          );
        }
      }

      // Start and width, from the row's start edge.
      for (final (j, box) in actions.indexed) {
        final expectedStart = (cells[j]['start']! as num).toDouble();
        final expectedWidth = (cells[j]['width']! as num).toDouble();
        final start = dir == 'ltr'
            ? _n(box, 'left') - _n(footer, 'left')
            : _n(footer, 'right') - _n(box, 'right');
        if (!_near(start, expectedStart)) {
          out.add(
            '$name: action $j starts at $start, expected $expectedStart',
          );
        }
        if (!_near(_n(box, 'width'), expectedWidth)) {
          out.add(
            '$name: action $j is ${_n(box, 'width')} wide, '
            'expected $expectedWidth',
          );
        }
      }

      // Lines: the actions the table puts on one line share a vertical
      // centre (the footer centres its items across), and each line starts
      // runSpacing below the bottom of the one above.
      final byLine = <int, List<Map<String, Object?>>>{};
      for (final (j, box) in actions.indexed) {
        byLine.putIfAbsent(cells[j]['line']! as int, () => []).add(box);
      }
      final lines = byLine.keys.toList()..sort();
      for (final line in lines) {
        final members = byLine[line]!;
        final centre =
            (_n(members.first, 'top') + _n(members.first, 'bottom')) / 2;
        for (final box in members.skip(1)) {
          final other = (_n(box, 'top') + _n(box, 'bottom')) / 2;
          if (!_near(other, centre)) {
            out.add(
              '$name: line $line does not share a centre ($centre vs $other)',
            );
          }
        }
      }
      for (final (k, line) in lines.indexed.skip(1)) {
        final above = byLine[lines[k - 1]]!;
        final below = byLine[line]!;
        final aboveBottom = above
            .map((box) => _n(box, 'bottom'))
            .reduce((x, y) => x > y ? x : y);
        final belowTop = below
            .map((box) => _n(box, 'top'))
            .reduce((x, y) => x < y ? x : y);
        if (!_near(belowTop - aboveBottom, runSpacing)) {
          out.add(
            '$name: line $line starts ${belowTop - aboveBottom}px below line '
            '${lines[k - 1]}, expected $runSpacing',
          );
        }
      }
    }

    return out;
  }

  // The skip says where it looked, so a skipped run is not read as a pass.
  final unsetNote = (Platform.environment['CHROME_EXECUTABLE'] ?? '').isEmpty
      ? ' (CHROME_EXECUTABLE unset)'
      : '';
  final skip = chromePath == null
      ? 'no local Chrome — tried ${chromeCandidates.join(', ')}$unsetNote; '
            'the stretch vectors cannot be checked against Chrome here'
      : null;

  test(
    'left to right, every action lands where the table says',
    () async {
      expect(disagreements(await measure('ltr'), 'ltr'), isEmpty);
    },
    skip: skip,
  );

  test(
    'right to left, every action lands where the table says, measured from '
    'the right',
    () async {
      expect(disagreements(await measure('rtl'), 'rtl'), isEmpty);
    },
    skip: skip,
  );
}

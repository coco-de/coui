// The line box Chrome draws — the Chrome half of the shared line box vectors
// (`packages/coui_core/test/fixtures/line_box_vectors.json`).
//
// Flutter's engine lays every line out at a whole pixel, so the Web emits the
// box a multiplier draws as a whole-pixel length
// (`CssVariableGenerator.lineHeightCss`): a 14px label at 1.4 sits in 20px on
// both platforms instead of 20 on one and 19.6 on the other. The unit tests
// read the declaration; what the browser makes of
// `round(nearest, calc(1.4 * 1em), 1px)` lives in the computed style, so this
// file reads it — for every role class through one, two and three lines, and
// for a size and leading stated inline through `toInlineCss`. The numbers are
// the table the Flutter line metrics test reads.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// The table shared with the Core and Flutter tests.
const String _kVectorsPath =
    'packages/coui_core/test/fixtures/line_box_vectors.json';

/// Within a hundredth of a pixel — the browser holds a length in 1/64 px.
const double _kEpsilon = 0.01;

/// How many lines each probe stacks — one, then enough to show the boxes
/// add up instead of drifting.
const List<int> _kLineCounts = [1, 2, 3];

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

/// The text of one line — a Latin descender and a Hangul syllable.
const String _kLine = 'Ag 가';

/// The computed line height and the laid-out height (px) of every element
/// with an id.
const String _kMeasureJs = '''
() => {
  const out = {};
  for (const el of document.querySelectorAll('[data-line-box]')) {
    out[el.id] = {
      lineHeight: parseFloat(getComputedStyle(el).lineHeight),
      height: el.getBoundingClientRect().height,
    };
  }
  return JSON.stringify(out);
}
''';

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();

  final vectors =
      jsonDecode(File(p.join(repoRoot, _kVectorsPath)).readAsStringSync())
          as Map<String, dynamic>;
  final roles = (vectors['roles'] as List).cast<Map<String, dynamic>>();
  final overlays = (vectors['overlays'] as List).cast<Map<String, dynamic>>();

  /// A real `CoUIWeb` root under the vendored Tailwind head, held to the
  /// desktop tier so the heading roles keep the sizes the table lists.
  Component page(Component child) => .fragment([
    Document.head(
      children: [
        Component.element(
          tag: 'script',
          children: [RawText(vendoredScript)],
        ),
        Component.element(
          tag: 'script',
          children: [RawText(themeConfig.tailwindConfig)],
        ),
        Component.element(
          tag: 'style',
          children: [RawText(themeConfig.cssVariables)],
        ),
        Component.element(
          tag: 'style',
          children: [RawText(buildLocalFontFaceCss())],
        ),
      ],
    ),
    CoUIWeb(theme: .coui, typographyTier: .desktop, child: child),
  ]);

  /// One probe — [lineCount] lines of a `Text`, broken apart by `<br>`.
  Component probe(
    String id, {
    required int lineCount,
    String? classes,
    Map<String, String> inline = const {},
  }) => div(
    [
      for (var line = 0; line < lineCount; line++) ...[
        if (line > 0) const br(),
        const Text(_kLine),
      ],
    ],
    id: id,
    classes: classes,
    attributes: const {'data-line-box': ''},
    styles: inline.isEmpty ? null : Styles(raw: inline),
  );

  /// Loads [html] offline in headless Chrome and returns what [script]
  /// evaluates to once the fonts are in.
  Future<T> evaluateIn<T>(String html, String script) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'coui-parity-line-box-probe-',
    );
    final browser = await pptr.puppeteer.launch(executablePath: chromePath);
    try {
      final file = File(p.join(tempDir.path, 'line-box.html'))
        ..writeAsStringSync(html);
      final chrome = await browser.newPage();
      await chrome.setOfflineMode(true);
      final _ = await chrome.goto(
        Uri.file(file.path).toString(),
        wait: pptr.Until.load,
      );
      await chrome.evaluate<void>('() => document.fonts.ready.then(() => {})');

      return await chrome.evaluate<T>(script);
    } finally {
      await browser.close();
      tempDir.deleteSync(recursive: true);
    }
  }

  /// Reads every probe of [html].
  Future<Map<String, ({double lineHeight, double height})>> measure(
    String html,
  ) async {
    final json =
        jsonDecode(await evaluateIn<String>(html, _kMeasureJs))
            as Map<String, dynamic>;

    return {
      for (final MapEntry(:key, :value) in json.entries)
        key: (
          lineHeight: ((value as Map)['lineHeight'] as num).toDouble(),
          height: (value['height'] as num).toDouble(),
        ),
    };
  }

  /// The computed line height (px) of the element [selector] finds in
  /// [html].
  Future<double> computedLineHeight(String html, String selector) async {
    final element = 'document.querySelector(${jsonEncode(selector)})';
    final value = await evaluateIn<num>(
      html,
      '() => parseFloat(getComputedStyle($element).lineHeight)',
    );

    return value.toDouble();
  }

  /// Every disagreement at once — one probe's failure says little about
  /// which emit is off.
  List<String> disagreements(
    Map<String, ({double lineHeight, double height})> measured,
    String id,
    double box,
    int lineCount,
  ) {
    final read = measured[id];
    if (read == null) return ['$id was not laid out'];

    return [
      if ((read.lineHeight - box).abs() > _kEpsilon)
        '$id line height ${read.lineHeight}, the table says $box',
      if ((read.height - box * lineCount).abs() > _kEpsilon)
        '$id height ${read.height}, the table says ${box * lineCount}',
    ];
  }

  // No local Chrome — the computed claims cannot be verified here.
  final skip = chromePath == null;

  group('LineBoxProbe — the line box Chrome lays text out in', () {
    testServer(
      'every role class draws the table box, line after line',
      (tester) async {
        tester.pumpComponent(
          page(
            div([
              for (final row in roles)
                for (final lineCount in _kLineCounts)
                  probe(
                    'r-${row['role']}-$lineCount',
                    lineCount: lineCount,
                    classes: 'text-${row['role']}',
                  ),
            ]),
          ),
        );
        final measured = await measure((await tester.request('/')).body);

        expect([
          for (final row in roles)
            for (final lineCount in _kLineCounts)
              ...disagreements(
                measured,
                'r-${row['role']}-$lineCount',
                (row['box'] as num).toDouble(),
                lineCount,
              ),
        ], isEmpty);
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testServer(
      'a size and leading stated inline draw the table box',
      (tester) async {
        tester.pumpComponent(
          page(
            div([
              for (final (index, row) in overlays.indexed)
                probe(
                  'o-$index',
                  lineCount: 2,
                  inline: CoreTextStyle(
                    fontSize: (row['fontSize'] as num).toDouble(),
                    lineHeight: (row['lineHeight'] as num).toDouble(),
                    fontFamily: CoreFontFamily.sans,
                  ).toInlineCss(),
                ),
            ]),
          ),
        );
        final measured = await measure((await tester.request('/')).body);

        expect([
          for (final (index, row) in overlays.indexed)
            ...disagreements(
              measured,
              'o-$index',
              (row['box'] as num).toDouble(),
              2,
            ),
        ], isEmpty);
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // A role class draws its box as a length, and a length is what an
    // element below it inherits. Flutter hands the multiplier down instead,
    // so text that changes only its size must not inherit the 14px line.
    testServer(
      'text that changes only its size keeps the inherited multiplier',
      (tester) async {
        tester.pumpComponent(
          page(
            div([
              // An app's own markup under the root: the root keeps the
              // body multiplier, so 18px at 1.5 is 27.
              probe(
                'raw-18',
                lineCount: 2,
                inline: const {'font-size': '18px'},
              ),
              // The Text chain's size inside a label wrapper: the label's
              // 1.4 at 12px is 16.8, drawn on the whole pixel as 17. The
              // chain states it on its own span — the element read here.
              div(
                [const Text(_kLine).s12],
                id: 'chain-12',
                classes: 'text-label-large',
              ),
            ]),
          ),
        );
        final html = (await tester.request('/')).body;
        final measured = await measure(html);

        expect(
          [...disagreements(measured, 'raw-18', 27, 2)],
          isEmpty,
          reason: 'the root hands 1.5 down, not its 21px line',
        );
        expect(
          await computedLineHeight(html, '#chain-12 > span'),
          closeTo(17, _kEpsilon),
          reason: 'the label hands 1.4 down, not its 20px line',
        );
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

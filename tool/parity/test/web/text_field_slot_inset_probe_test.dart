// A TextField's leading / trailing slots, rendered — where a real Chrome with
// the vendored Tailwind puts them inside the framed box.
//
// Flutter pads the whole row (prefix + input + suffix), so a slot starts the
// field's inset inside the border: border + inset from the box's outer edge.
// The Web unit tests read where the markup puts the padding; this file reads
// the laid-out rects, so a slot back on the border fails here even if the
// declarations look right.
//
// Every expected distance is the box's computed border width plus the Core
// inset that box states — the size row's, or the composing parent's own.
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

/// The width of every probe's host, in CSS px.
const double kProbeWidth = 240;

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

const List<CoreSelectItem<String>> _kItems = [
  CoreSelectItem(value: 'apple', label: 'Apple'),
];

/// The size row's inset with a one-line field's vertical inset dropped.
CoreEdgeInsets _rowInset(CoreComponentSize size) =>
    CoreTextFieldStyle.contentPadding(
      statedPadding: null,
      rowPadding: CoreTextFieldStyle.defaultsBySize[size]!.padding!,
      singleLine: true,
      height: null,
      minHeight: null,
    );

/// One probe: what to render, the inset its box states, and which sides
/// carry a slot.
class _Case {
  const _Case(
    this.name,
    this.build, {
    required this.inset,
    required this.leading,
    required this.trailing,
  });

  final String name;
  final Component Function() build;
  final CoreEdgeInsets inset;
  final bool leading;
  final bool trailing;
}

final List<_Case> _cases = [
  _Case(
    'TextField md prefix + suffix',
    () => const TextField(
      prefix: Icon(LucideIcons.search),
      suffix: Icon(LucideIcons.x),
    ),
    inset: _rowInset(CoreComponentSize.md),
    leading: true,
    trailing: true,
  ),
  _Case(
    'TextField sm prefix + suffix',
    () => const TextField(
      size: CoreComponentSize.sm,
      prefix: Icon(LucideIcons.search),
      suffix: Icon(LucideIcons.x),
    ),
    inset: _rowInset(CoreComponentSize.sm),
    leading: true,
    trailing: true,
  ),
  _Case(
    'NumberInput md',
    () => const NumberInput(value: 3),
    inset: CoreNumberInputStyle.defaultFieldStyle.padding!,
    leading: true,
    trailing: true,
  ),
  _Case(
    'Select md',
    () => const Select<String>(items: _kItems),
    inset: _rowInset(CoreComponentSize.md),
    leading: false,
    trailing: true,
  ),
  _Case(
    'DatePicker md',
    () => DatePicker(onChanged: (_) {}),
    inset: _rowInset(CoreComponentSize.md),
    leading: false,
    trailing: true,
  ),
  _Case(
    'TimePicker md',
    () => const TimePicker(value: '14:30'),
    inset: _rowInset(CoreComponentSize.md),
    leading: false,
    trailing: true,
  ),
  _Case(
    'ItemPicker search',
    () => ItemPicker(
      items: const ['Apple', 'Banana'],
      onChanged: (_) {},
    ),
    inset: CoreItemPickerStyle.defaultSearchFieldStyle.padding!,
    leading: true,
    trailing: false,
  ),
];

/// For every probe: the framed box (the `<input>`'s parent), its border
/// widths, and its first and last child's rects.
const String _kMeasureJs = '''
() => {
  const rect = (el) => {
    const r = el.getBoundingClientRect();
    return {left: r.left, right: r.right};
  };
  const out = {};
  for (const host of document.querySelectorAll('[data-probe]')) {
    const input = host.querySelector('input:not([type="hidden"])');
    const box = input.parentElement;
    const cs = getComputedStyle(box);
    out[host.getAttribute('data-probe')] = {
      box: rect(box),
      borderLeft: parseFloat(cs.borderLeftWidth),
      borderRight: parseFloat(cs.borderRightWidth),
      first: rect(box.firstElementChild),
      last: rect(box.lastElementChild),
      input: rect(input),
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
    workDir = Directory.systemTemp.createTempSync('text-field-slot-probe-');
    browser = await launchCaptureBrowser(
      width: 800,
      height: 1200,
      executablePath: chromePath,
    );
    final bodyHtml = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        Theme.defaults(
          child: div([
            for (final (i, c) in _cases.indexed)
              div(
                [c.build()],
                attributes: {'data-probe': 'slot-$i'},
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
    final file = File(p.join(workDir.path, 'slots.html'))
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

  group('TextField slots in Chrome sit inside the inset', () {
    for (final (i, c) in _cases.indexed) {
      test(c.name, () {
        final m = measured['slot-$i']!;
        double n(String key, String side) =>
            ((m[key]! as Map)[side]! as num).toDouble();
        final borderLeft = (m['borderLeft']! as num).toDouble();
        final borderRight = (m['borderRight']! as num).toDouble();
        final lead = n('first', 'left') - n('box', 'left');
        final trail = n('box', 'right') - n('last', 'right');
        // ignore: avoid_print — the measured table the report quotes.
        print('MEASURE ${c.name}: lead=$lead trail=$trail');

        if (c.leading) {
          expect(
            lead,
            closeTo(borderLeft + c.inset.left, 0.01),
            reason: 'the leading slot starts border + inset from the edge',
          );
        } else {
          expect(
            n('input', 'left') - n('box', 'left'),
            closeTo(borderLeft, 0.01),
            reason: 'with no leading slot the input fills from the border',
          );
        }
        if (c.trailing) {
          expect(
            trail,
            closeTo(borderRight + c.inset.right, 0.01),
            reason: 'the trailing slot ends border + inset from the edge',
          );
        }
      }, skip: skip);
    }
  });
}

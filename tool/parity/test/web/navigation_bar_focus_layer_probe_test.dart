// A NavigationBar destination under keyboard focus, in a real Chrome — whether
// the 8 % focus layer actually paints, and where (#5740).
//
// The Web resolver writes the layer as a scoped rule keyed on the chrome
// `<div>`'s class, and the unit tests read that rule as text. Text proves the
// declaration, not the match: the chrome never takes focus — its parent, the
// destination's `Clickable` root, does — so a rule written on the chrome's own
// `:focus-visible` read correctly and painted nothing. This probe presses Tab
// and reads the computed face of the focused chrome against its resting face
// and against an unfocused neighbour, and the chrome's box against the
// Clickable's: Flutter lays the layer across the whole cell, over the
// selection when the destination is selected.
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

Component _bar(CoreNavigationBarMode mode) => div(
  [
    NavigationBar(
      id: 'nav-${mode.name}',
      mode: mode,
      selectedIndex: 0,
      onSelected: (_) {},
      items: const [
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.house),
          label: 'Home',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.search),
          label: 'Search',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.heart),
          label: 'Likes',
        ),
      ],
    ),
  ],
  styles: Styles(
    raw: {
      'width': mode == CoreNavigationBarMode.bar ? '276px' : '120px',
    },
  ),
);

/// The faces of the chrome `<div>`s of the bar [id], and the boxes of the
/// first chrome and its Clickable root.
String _readJs(String id) =>
    '''
() => {
  const nav = document.getElementById('$id');
  const chromes = [...nav.querySelectorAll('[data-coui-nav-chrome]')];
  const box = (el) => {
    const r = el.getBoundingClientRect();
    return {width: r.width, height: r.height};
  };
  return JSON.stringify({
    faces: chromes.map((c) => getComputedStyle(c).backgroundColor),
    active: document.activeElement === chromes[0].parentElement,
    chrome: box(chromes[0]),
    clickable: box(chromes[0].parentElement),
  });
}
''';

void main() {
  final chromePath = _systemChromePath();
  late pptr.Browser browser;
  late Directory workDir;
  final rest = <CoreNavigationBarMode, Map<String, Object?>>{};
  final focused = <CoreNavigationBarMode, Map<String, Object?>>{};

  setUpAll(() async {
    if (chromePath == null) return;
    workDir = Directory.systemTemp.createTempSync('nav-focus-layer-probe-');
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
    for (final mode in [
      CoreNavigationBarMode.bar,
      CoreNavigationBarMode.rail,
    ]) {
      final bodyHtml = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          Theme.defaults(child: _bar(mode)),
        ]),
      );
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: bodyHtml,
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        // No transition: the computed face is read at once, not mid-fade.
        additionalHeadHtml:
            '<style>body{margin:0}*{transition:none!important}</style>',
      );
      final file = File(p.join(workDir.path, '${mode.name}.html'))
        ..writeAsStringSync(html);
      final page = await browser.newPage();
      try {
        await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
        final id = 'nav-${mode.name}';
        rest[mode] =
            jsonDecode(await page.evaluate<String>(_readJs(id)))
                as Map<String, Object?>;
        // Tab from the document start lands on the first destination —
        // keyboard focus, so `:focus-visible` matches.
        await page.keyboard.press(pptr.Key.tab);
        focused[mode] =
            jsonDecode(await page.evaluate<String>(_readJs(id)))
                as Map<String, Object?>;
      } finally {
        await page.close();
      }
    }
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    workDir.deleteSync(recursive: true);
  });

  final skip = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

  for (final mode in [CoreNavigationBarMode.bar, CoreNavigationBarMode.rail]) {
    test('${mode.name} — the focused destination lays the layer', () {
      final before = rest[mode]!;
      final after = focused[mode]!;
      expect(after['active'], isTrue, reason: 'Tab focuses the destination');
      final restFaces = (before['faces']! as List).cast<String>();
      final focusFaces = (after['faces']! as List).cast<String>();
      // The focused (and selected) destination's face moves; its unfocused
      // neighbours keep theirs.
      expect(
        focusFaces[0],
        isNot(restFaces[0]),
        reason: 'rest ${restFaces[0]}, focused ${focusFaces[0]}',
      );
      expect(focusFaces.sublist(1), restFaces.sublist(1));
      // Across the whole cell — the chrome fills its Clickable.
      final chrome = after['chrome']! as Map<String, Object?>;
      final clickable = after['clickable']! as Map<String, Object?>;
      expect(chrome['width'], clickable['width']);
      expect(chrome['height'], clickable['height']);
      // The measured faces are the probe's report, read when a run is
      // compared against the Flutter twin's wash.
      // ignore: avoid_print
      print(
        '${mode.name}: rest ${restFaces[0]} → focused ${focusFaces[0]}, '
        'cell ${chrome['width']}×${chrome['height']}',
      );
    }, skip: skip);
  }
}

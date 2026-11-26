// Where the Accordion chevron sits, read from real Chrome.
//
// Flutter centres the chevron's own box in the trigger row and turns that
// box half a turn when the item opens, so the glyph stays on the row's
// centre in both states. A Web icon is an inline box that sits on the
// text baseline; wrapped in a plain span it lands on a line as tall as the
// trigger's label and off that line's centre, and the span's rotation then
// turns it about the line's centre instead of its own — the closed chevron
// drew 1.5px above Flutter's and the open one 1.5px below. A VM test sees
// only class names, so this reads the laid-out boxes.
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

/// Accordion labels whose line box is taller than the chevron, so a
/// chevron off its own centre shows.
const _kTitles = ['환불 정책은 어떻게 되나요?', '요금제는 어떻게 해지하나요?'];

void main() {
  late pptr.Browser browser;
  late Directory work;
  late List<dynamic> rows;

  setUpAll(() async {
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        CoUIWeb(
          theme: .coui,
          child: div(
            [
              Accordion(
                items: [
                  AccordionItem(
                    title: _kTitles[0],
                    content: const Text('펼친 항목'),
                    expanded: true,
                  ),
                  AccordionItem(
                    title: _kTitles[1],
                    content: const Text('접힌 항목'),
                  ),
                ],
              ),
            ],
            styles: const Styles(raw: {'width': '360px'}),
          ),
        ),
      ]),
    );
    work = Directory.systemTemp.createTempSync('accordion-chevron-');
    final file = File('${work.path}/index.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml:
              '<style>${buildLocalFontFaceCss()}</style>'
              '${buildLocalIconifyHeadHtml()}',
        ),
      );
    browser = await launchCaptureBrowser(width: 800, height: 800);
    final page = await browser.newPage();
    await page.setOfflineMode(true);
    await page.goto(Uri.file(file.path).toString(), wait: .load);
    await page.evaluate<Object?>('() => document.fonts.ready');
    // Settle the rotation transition: read the end state, not a frame of
    // the turn.
    await page.evaluate<Object?>('''
() => {
  for (const e of document.querySelectorAll('*')) {
    e.style.transitionDuration = '0s';
  }
}''');
    rows =
        jsonDecode(
              await page.evaluate<String>('''
() => {
  const rect = e => {
    const r = e.getBoundingClientRect();
    return {y: r.y, h: r.height};
  };
  const out = [];
  for (const trigger of document.querySelectorAll('[aria-expanded]')) {
    const glyph = trigger.querySelector('svg, iconify-icon');
    const wrapper = glyph.parentElement;
    out.push({
      expanded: trigger.getAttribute('aria-expanded'),
      row: rect(glyph.closest('.flex-1') ?? trigger),
      glyph: rect(glyph),
      wrapper: rect(wrapper),
    });
  }
  return JSON.stringify(out);
}'''),
            )
            as List<dynamic>;
  });

  tearDownAll(() async {
    await browser.close();
    work.deleteSync(recursive: true);
  });

  test('both items are measured, one open and one closed', () {
    expect(rows.map((r) => (r as Map)['expanded']), ['true', 'false']);
  });

  for (final (index, state) in [(0, 'open'), (1, 'closed')]) {
    test('the $state chevron sits on the centre of its trigger row', () {
      final row = (rows[index] as Map)['row'] as Map;
      final glyph = (rows[index] as Map)['glyph'] as Map;
      final rowCentre = (row['y'] as num) + (row['h'] as num) / 2;
      final glyphCentre = (glyph['y'] as num) + (glyph['h'] as num) / 2;
      expect(glyphCentre, closeTo(rowCentre, 0.01));
    });

    test('the $state chevron turns about its own centre', () {
      final glyph = (rows[index] as Map)['glyph'] as Map;
      final wrapper = (rows[index] as Map)['wrapper'] as Map;
      // A wrapper as tall as the glyph turns the glyph in place.
      expect(wrapper['h'], closeTo(glyph['h'] as num, 0.01));
      expect(wrapper['y'], closeTo(glyph['y'] as num, 0.01));
    });
  }
}

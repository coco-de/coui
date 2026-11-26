// keyMinSize constrains the padded interior; a visible border grows the cap.
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' show Browser, Page;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  late Browser browser;
  late Page page;
  late Directory directory;

  setUpAll(() async {
    browser = await launchCaptureBrowser(width: 800, height: 600);
    directory = Directory.systemTemp.createTempSync('kbd-min-size-');
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });
  setUp(() async => page = await browser.newPage());
  tearDown(() => page.close());

  Future<void> render(
    String theme,
    CoreSurfaceStyleId surfaceStyle, {
    bool hiddenBorder = false,
  }) async {
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        CoUIWeb(
          theme: .coui,
          child: div([
            for (final width in [0.0, 0.5, 1.0, 2.0])
              Kbd(
                id: 'width-${(width * 10).round()}',
                keys: const ['I', 'J'],
                kbdStyle: CoreKbdStyle(
                  keyMinSize: 40,
                  keyBorderWidth: width,
                  keyBorderColor: hiddenBorder ? CoreColor.transparent : null,
                ),
              ),
          ]),
        ),
      ]),
    );
    final fixture = File('${directory.path}/index.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          theme: theme,
          surfaceStyleId: surfaceStyle.name,
          additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
        ),
      );
    await page.goto(fixture.uri.toString());
    await page.evaluate<void>('() => document.fonts.ready');
  }

  Future<List<Map<String, Object?>>> measure() async =>
      (await page.evaluate<List<dynamic>>(
        '''
      () =>
        [...document.querySelectorAll('[id^="width-"]')].map(root => {
          const caps = [...root.children].map(cap => {
            const r = cap.getBoundingClientRect();
            return {width:r.width, height:r.height, left:r.left, right:r.right};
          });
          return {id:root.id, caps, label:root.getAttribute('aria-label')};
        })'''
            .trim(),
      )).cast<Map<String, Object?>>();

  for (final theme in ['light', 'dark']) {
    for (final surface in [
      CoreSurfaceStyleId.defaultStyle,
      CoreSurfaceStyleId.neoBrutalism,
    ]) {
      for (final hidden in [false, true]) {
        test(
          '$theme / ${surface.name} / hidden=$hidden interior floor',
          () async {
            await render(theme, surface, hiddenBorder: hidden);
            final rows = await measure();
            for (final row in rows) {
              final width = int.parse((row['id']! as String).substring(6)) / 10;
              final stroke = hidden
                  ? 0.0
                  : CoreSurfaceRecipe.of(surface).geometry.stroke(
                      // The Web hairline is one CSS pixel on a 1x screen.
                      width == CoreStrokeWidth.stroke0_5
                          ? CoreStrokeWidth.stroke1
                          : width,
                    );
              final caps = (row['caps']! as List).cast<Map<String, Object?>>();
              for (final cap in caps) {
                expect(cap['width'], closeTo(40 + stroke * 2, 0.01));
                expect(cap['height'], closeTo(40 + stroke * 2, 0.01));
              }
              expect((caps[1]['left']! as num) - (caps[0]['right']! as num), 4);
              expect(row['label'], 'I J');
            }
          },
        );
      }
    }
    test(
      '$theme / host content-box reset preserves the interior floor',
      () async {
        await render(theme, .defaultStyle);
        await page.evaluate<void>(
          '''
        () => {
          const style = document.createElement('style');
          style.textContent = 'span { box-sizing: content-box; }';
          document.head.append(style);
        }
      '''
              .trim(),
        );
        final rows = await measure();
        final caps = (rows.last['caps']! as List).cast<Map<String, Object?>>();
        for (final cap in caps) {
          expect(cap['width'], 44);
          expect(cap['height'], 44);
        }
      },
    );
  }
}

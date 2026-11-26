import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/protocol/emulation.dart' as protocol;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  late pptr.Browser browser;
  late pptr.Page page;
  late Directory directory;

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('tabs-rule-');
    browser = await launchCaptureBrowser(width: 800, height: 1200);
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        CoUIWeb(
          theme: .coui,
          child: div([
            for (final size in CoreTabsSize.values)
              Tabs(
                id: size.name,
                selectedIndex: 0,
                variant: .underline,
                size: size,
                tabs: const [CoreTabItem<Component>(label: 'First')],
                onChanged: (_) {},
              ),
            Tabs(
              id: 'custom',
              selectedIndex: 0,
              variant: .underline,
              tabsStyle: const CoreTabsStyle(borderWidth: 3),
              tabs: const [CoreTabItem<Component>(label: 'First')],
              onChanged: (_) {},
            ),
            div(
              [
                Tabs(
                  id: 'scrolling',
                  selectedIndex: 0,
                  variant: .underline,
                  scrollable: true,
                  tabs: [
                    for (var i = 0; i < 12; i++)
                      CoreTabItem<Component>(label: 'Long destination $i'),
                  ],
                  onChanged: (_) {},
                ),
              ],
              styles: const Styles(raw: {'width': '220px'}),
            ),
          ]),
        ),
      ]),
    );
    final file = File('${directory.path}/index.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
        ),
      );
    page = await browser.newPage();
    await page.goto(file.uri.toString());
    await page.evaluate<void>('() => document.fonts.ready');
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });

  Future<Map<String, dynamic>> measure(String id) async =>
      (jsonDecode(
                await page.evaluate<String>('''
() => {
  const bar = document.getElementById('$id');
  const rule = getComputedStyle(bar.querySelector('[data-coui-tabs-rule]'));
  return JSON.stringify({height:bar.getBoundingClientRect().height,
    ruleWidth:parseFloat(rule.borderBottomWidth),
    ruleStyle:rule.borderBottomStyle,
    actualBorder:parseFloat(getComputedStyle(bar).borderBottomWidth)});
}
'''),
              )
              as Map)
          .cast();

  test('separator overlays each outside-height rung', () async {
    for (final row in {'sm': 32, 'md': 40, 'lg': 48}.entries) {
      final result = await measure(row.key);
      expect(result['height'], row.value);
      expect(result['actualBorder'], 0);
      expect(result['ruleWidth'], 1);
      expect(result['ruleStyle'], 'solid');
    }
  });

  test('a border-width override paints without changing layout', () async {
    final result = await measure('custom');
    expect(result['height'], 40);
    expect(result['ruleWidth'], 3);
  });

  test('scrolling labels does not scroll the separator host', () async {
    final result =
        jsonDecode(
              await page.evaluate<String>('''
() => {
  const bar=document.getElementById('scrolling'), strip=bar.querySelector('[data-coui-tabs-scroll]');
  strip.scrollLeft=strip.scrollWidth;
  return JSON.stringify({hostScroll:bar.scrollLeft,stripScroll:strip.scrollLeft,
    width:bar.getBoundingClientRect().width,height:bar.getBoundingClientRect().height,
    ruleWidth:bar.querySelector('[data-coui-tabs-rule]').getBoundingClientRect().width});
}
'''),
            )
            as Map;
    expect(result['hostScroll'], 0);
    expect(result['stripScroll'], greaterThan(0));
    expect(result['width'], 220);
    expect(result['ruleWidth'], 220);
    expect(result['height'], 40);
  });

  test('forced colours retain a real border rather than a shadow', () async {
    await page.devTools.emulation.setEmulatedMedia(
      features: [protocol.MediaFeature(name: 'forced-colors', value: 'active')],
    );
    expect(
      await page.evaluate<bool>(
        "() => matchMedia('(forced-colors: active)').matches",
      ),
      isTrue,
    );
    final result = await measure('md');
    expect(result['height'], 40);
    expect(result['ruleStyle'], 'solid');
    expect(result['ruleWidth'], 1);
  });
}

// A slot has to supply the Icon's ambient data, not just its wrapper's
// font-size: Icon resolves its own width before CSS inheritance applies.
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

void main() {
  late pptr.Browser browser;
  late Directory work;
  late Map<String, dynamic> measurements;

  setUpAll(() async {
    final children = <Component>[];
    for (final variant in CoreTabPaneVariant.values) {
      for (final direction in ['ltr', 'rtl']) {
        for (final mode in [
          'default',
          'slot',
          'explicit',
          'explicit-trailing',
          'nested',
          'nested-trailing',
          'disabled',
          'theme',
          'theme-instance',
          'icon-theme',
        ]) {
          final id = '${variant.name}-$direction-$mode';
          Component leading = Icon(
            LucideIcons.fileCode,
            id: '$id-leading',
            iconStyle: mode == 'explicit'
                ? const CoreIconStyle(size: 12, color: CoreColor(0xFF00FF00))
                : null,
          );
          if (mode == 'nested') {
            leading = IconTheme(
              data: const IconThemeData(size: 28, color: CoreColor(0xFF0000FF)),
              child: leading,
            );
          }
          Component trailing = Icon(
            LucideIcons.star,
            id: '$id-trailing',
            iconStyle: mode == 'explicit-trailing'
                ? const CoreIconStyle(size: 12, color: CoreColor(0xFF00FF00))
                : null,
          );
          if (mode == 'nested-trailing') {
            trailing = IconTheme(
              data: const IconThemeData(size: 28, color: CoreColor(0xFF0000FF)),
              child: trailing,
            );
          }
          final pane = TabPane(
            id: id,
            variant: variant,
            selectedIndex: 0,
            onChanged: (_) {},
            tabPaneStyle: mode == 'slot' || mode == 'theme-instance'
                ? const CoreTabPaneStyle(slotIconStyle: CoreIconStyle(size: 24))
                : null,
            tabs: [
              CoreTabItem<Component>(
                label: 'main.dart',
                leading: leading,
                trailing: trailing,
                onClose: () {},
                enabled: mode != 'disabled',
              ),
            ],
          );
          children.add(
            div(
              [
                Theme(
                  data: ThemeData(
                    coreComponentTheme: CoreComponentTheme(
                      tabPane: mode == 'theme' || mode == 'theme-instance'
                          ? const CoreTabPaneTheme(
                              style: CoreTabPaneStyle(
                                slotIconStyle: CoreIconStyle(size: 20),
                              ),
                            )
                          : null,
                      icon: mode == 'icon-theme'
                          ? const CoreIconTheme(
                              style: CoreIconStyle(
                                size: 22,
                                color: CoreColor(0xFF800080),
                              ),
                            )
                          : null,
                    ),
                  ),
                  child: IconTheme(
                    data: const IconThemeData(
                      size: 30,
                      color: CoreColor(0xFFFF0000),
                    ),
                    child: pane,
                  ),
                ),
              ],
              styles: Styles(raw: {'width': '400px', 'direction': direction}),
            ),
          );
        }
      }
    }
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        CoUIWeb(theme: .coui, child: div(children)),
      ]),
    );
    work = Directory.systemTemp.createTempSync('weever-tab-pane-slots-');
    final file = File('${work.path}/index.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml:
              '<style>${buildLocalFontFaceCss()}</style>${buildLocalIconifyHeadHtml()}',
        ),
      );
    browser = await launchCaptureBrowser(width: 800, height: 1200);
    final page = await browser.newPage();
    await page.setOfflineMode(true);
    await page.goto(Uri.file(file.path).toString(), wait: .load);
    await page.evaluate<Object?>('() => document.fonts.ready');
    measurements =
        jsonDecode(
              await page.evaluate<String>(r'''
() => {
      const out={};
      for(const pane of document.querySelectorAll('[role=tablist]')) {
        const root=pane.parentElement,id=root.id;
        const rect=e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height,color:getComputedStyle(e).color};};
        const lead=root.querySelector('[id$="-leading"]'),trail=root.querySelector('[id$="-trailing"]');
        const tab=root.querySelector('[role=tab]');
        const label=[...tab.querySelectorAll('span')].find(e=>e.childNodes.length===1&&e.firstChild.nodeType===3&&e.textContent==='main.dart');
        const close=root.querySelector('button svg');
        out[id]={lead:rect(lead),trail:rect(trail),bar:rect(pane),label:rect(label),close:rect(close),disabled:tab.getAttribute('aria-disabled')};
      }
      return JSON.stringify(out);
    }'''),
            )
            as Map<String, dynamic>;
  });

  tearDownAll(() async {
    await browser.close();
    work.deleteSync(recursive: true);
  });

  for (final variant in CoreTabPaneVariant.values) {
    for (final direction in ['ltr', 'rtl']) {
      for (final mode in [
        'default',
        'slot',
        'explicit',
        'explicit-trailing',
        'nested',
        'nested-trailing',
        'disabled',
        'theme',
        'theme-instance',
        'icon-theme',
      ]) {
        final id = '${variant.name}-$direction-$mode';
        test('$id preserves slot sizing and explicit precedence', () {
          final m = measurements[id] as Map;
          final lead = m['lead'] as Map;
          final trail = m['trail'] as Map;
          final slotSize = switch (mode) {
            'slot' || 'theme-instance' => 24,
            'theme' => 20,
            'icon-theme' => 22,
            _ => CoreTabPaneStyle.defaultSlotIconStyle.size!,
          };
          final leadingSize = switch (mode) {
            'explicit' => 12,
            'nested' => 28,
            _ => slotSize,
          };
          expect([lead['w'], lead['h']], [leadingSize, leadingSize]);
          final trailingSize = switch (mode) {
            'explicit-trailing' => 12,
            'nested-trailing' => 28,
            _ => slotSize,
          };
          expect([trail['w'], trail['h']], [trailingSize, trailingSize]);
          final ambientColor = mode == 'icon-theme'
              ? 'rgb(128, 0, 128)'
              : 'rgb(255, 0, 0)';
          expect(lead['color'], switch (mode) {
            'explicit' => 'rgb(0, 255, 0)',
            'nested' => 'rgb(0, 0, 255)',
            _ => ambientColor,
          });
          expect(trail['color'], switch (mode) {
            'explicit-trailing' => 'rgb(0, 255, 0)',
            'nested-trailing' => 'rgb(0, 0, 255)',
            _ => ambientColor,
          });
          final bar = m['bar'] as Map;
          for (final icon in [lead, trail]) {
            expect(
              (icon['y'] as num) + (icon['h'] as num) / 2,
              (bar['y'] as num) + (bar['h'] as num) / 2,
            );
          }
          final label = m['label'] as Map;
          expect(
            direction == 'ltr'
                ? (lead['x'] as num) < (label['x'] as num)
                : (lead['x'] as num) > (label['x'] as num),
            isTrue,
          );
          if (variant == CoreTabPaneVariant.editorStrip) {
            expect(
              (m['close'] as Map)['w'],
              CoreTabPaneStyle.editorStrip.closeIconStyle!.size,
            );
          }
          if (mode == 'disabled') expect(m['disabled'], 'true');
        });
      }
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/helpers/brand_fixture.dart';
import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/core_opacity_scale_cases.dart';

double _alpha(String css) {
  final channels = RegExp(r'rgba?\(([^)]+)\)')
      .firstMatch(css)!
      .group(1)!
      .split(RegExp(r'[,\s/]+'))
      .where((value) => value.isNotEmpty)
      .map(double.parse)
      .toList();
  return channels.length == 3 ? 1 : channels[3];
}

void main() {
  late Browser browser;
  late Directory directory;
  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('core-opacity-scale-');
    browser = await launchCaptureBrowser(width: 800, height: 1000);
  });
  tearDownAll(() async {
    await browser.close();
  });

  // These four defaults exist in pinned Tailwind3.4.17 but not CoreOpacity.
  // Source: tailwindlabs/tailwindcss v3.4.17 stubs/config.full.js:702-724.
  const inheritedDefaults = {'35': 0.35, '45': 0.45, '55': 0.55, '65': 0.65};
  for (final mode in ['default', 'brand', 'caller']) {
    for (final theme in ['light', 'dark']) {
      test(
        '$mode/$theme paints the existing opacity scale and keeps extensions',
        () async {
          final cases = {
            ...coreOpacityCases,
            ...inheritedDefaults,
            if (mode == 'caller') '8': 0.27,
            if (mode == 'caller') 'caller': 0.37,
          };
          final body = await renderComponentBodyHtml(
            Theme.defaults(
              child: div([
                for (final key in cases.keys) ...[
                  div(const [], id: 'opacity-$key', classes: 'opacity-$key'),
                  div(const [], id: 'bg-$key', classes: 'bg-primary/$key'),
                  div(const [], id: 'text-$key', classes: 'text-primary/$key'),
                  div(
                    const [],
                    id: 'border-$key',
                    classes: 'border-primary/$key',
                  ),
                  div(
                    const [],
                    id: 'ring-$key',
                    classes: 'ring-2 ring-primary/$key',
                  ),
                ],
              ]),
            ),
          );
          final config = mode == 'brand'
              ? ThemeConfig(kBrandFixturePalette)
              : ThemeConfig.defaults();
          final custom = mode == 'caller'
              ? '''
<script>tailwind.config={...tailwind.config,theme:{
...tailwind.config.theme,extend:{...tailwind.config.theme.extend,
opacity:{...tailwind.config.theme.extend.opacity,8:"0.27",caller:"0.37"}}}}</script>'''
              : '';
          final file = File('${directory.path}/$mode-$theme.html')
            ..writeAsStringSync(
              buildOfflineTailwindHarnessHtml(
                bodyHtml: body,
                themeConfig: config,
                vendoredTailwindScript: loadVendoredTailwindScript(),
                theme: theme,
                additionalHeadHtml: custom,
              ),
            );
          final page = await browser.newPage();
          try {
            await page.goto(file.uri.toString());
            await page.waitForFunction(
              "getComputedStyle(document.getElementById('opacity-50'))"
              ".opacity==='0.5'",
            );
            // Play CDN wraps its configuration in a Proxy. Read a plain JSON
            // snapshot, rather than CDP's partial Proxy property preview.
            final opacityConfig =
                jsonDecode(
                      await page.evaluate<String>(
                        'JSON.stringify(tailwind.config.theme.extend.opacity)',
                      ),
                    )
                    as Map<String, dynamic>;
            expect(opacityConfig.keys.toSet(), {
              ...coreOpacityCases.keys,
              if (mode == 'caller') 'caller',
            });
            for (final entry in cases.entries) {
              final row = await page.evaluate<Map<String, Object?>>(
                '''
(key) => {
const style = name => getComputedStyle(document.getElementById(name+'-'+key));
return {opacity:style('opacity').opacity,bg:style('bg').backgroundColor,
text:style('text').color,border:style('border').borderTopColor,
ring:style('ring').getPropertyValue('--tw-ring-color')};
}''',
                args: [entry.key],
              );
              expect(double.parse(row['opacity']! as String), entry.value);
              for (final target in ['bg', 'text', 'border', 'ring']) {
                expect(
                  _alpha(row[target]! as String),
                  entry.value,
                  reason: '$mode/$theme/${entry.key}/$target',
                );
              }
            }
          } finally {
            await page.close();
          }
        },
      );
    }
  }
}

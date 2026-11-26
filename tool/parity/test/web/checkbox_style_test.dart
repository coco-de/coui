import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  test(
    'Checkbox dimensions retain exact sizes and variable behavior',
    () async {
      final boxSizes = <double?>[null, 16, 17.25, 24.5, 32, 19];
      final dashLengths = <double?>[null, 8, 7.25, 12.5, 24.5, 19];
      final checkedStates = <bool?>[false, true, null];
      final body = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          CoUIWeb(
            theme: .coui,
            child: div([
              for (var i = 0; i < boxSizes.length; i++)
                for (var j = 0; j < checkedStates.length; j++)
                  div([
                    Checkbox(
                      checked: checkedStates[j],
                      onChanged: (_) {},
                      checkboxStyle: CoreCheckboxStyle(boxSize: boxSizes[i]),
                    ),
                  ], id: 'box-$i-$j'),
              for (var i = 0; i < dashLengths.length; i++)
                div([
                  Checkbox(
                    checked: null,
                    onChanged: (_) {},
                    checkboxStyle: CoreCheckboxStyle(
                      boxSize: CoreSize.size32,
                      indeterminateLength: dashLengths[i],
                    ),
                  ),
                ], id: 'dash-$i'),
            ]),
          ),
        ]),
      );
      final dir = Directory.systemTemp.createTempSync('coui-checkbox-size-');
      final browser = await launchCaptureBrowser(width: 800, height: 1200);
      try {
        final page = await browser.newPage();
        await page.setOfflineMode(true);
        final errors = <String>[];
        page.onError.listen((error) => errors.add('$error'));

        Future<Map<String, dynamic>> dimensions(String id, bool dash) =>
            page.evaluate<Map<String, dynamic>>(
              '''
(id, dash) => {
  const root = document.getElementById(id);
  const box = root.querySelector('.co-checkbox-box');
  const element = dash ? box.querySelector('div') : box;
  const rect = element.getBoundingClientRect();
  return {width: rect.width, height: rect.height};
}
''',
              args: [id, dash],
            );

        Future<void> expectBox(String id, double expected) async {
          expect(
            await dimensions(id, false),
            {'width': expected, 'height': expected},
            reason: '$id must keep its requested square size',
          );
        }

        Future<void> expectDash(String id, double expected) async {
          final actual = await dimensions(id, true);
          expect(actual['width'], expected, reason: '$id dash length');
          expect(
            actual['height'],
            CoreCheckboxStyle.defaultMarkThickness,
            reason: '$id must preserve its independent thickness',
          );
        }

        for (final theme in ['light', 'dark']) {
          final html = File('${dir.path}/$theme.html')
            ..writeAsStringSync(
              buildOfflineTailwindHarnessHtml(
                bodyHtml: body,
                themeConfig: ThemeConfig.defaults(),
                theme: theme,
                vendoredTailwindScript: loadVendoredTailwindScript(),
                additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
              ),
            );
          await page.goto(html.uri.toString(), wait: .load);
          await page.evaluate<void>('() => document.fonts.ready');
          for (var i = 0; i < boxSizes.length; i++) {
            for (var j = 0; j < checkedStates.length; j++) {
              await expectBox('box-$i-$j', boxSizes[i] ?? 16);
            }
          }
          for (var i = 0; i < dashLengths.length; i++) {
            await expectDash('dash-$i', dashLengths[i] ?? 8);
          }

          // On-scale lengths still follow the existing size variables.
          // Off-scale values must not borrow a neighbouring token.
          await page.evaluate<void>('''
() => {
  const root = document.documentElement.style;
  root.setProperty('--coui-size-16', '1.25rem');
  root.setProperty('--coui-size-8', '0.625rem');
}
''');
          await expectBox('box-0-0', 20);
          await expectBox('box-1-0', 20);
          await expectBox('box-2-0', 17.25);
          await expectDash('dash-0', 10);
          await expectDash('dash-1', 10);
          await expectDash('dash-2', 7.25);

          // Size is independent of spacing and the density control ladder.
          await page.evaluate<void>('''
() => {
  const root = document.documentElement.style;
  root.setProperty('--coui-space-16', '3rem');
  root.setProperty('--coui-control-height-40', '9rem');
}
''');
          await expectBox('box-0-0', 20);
          await expectBox('box-2-0', 17.25);
          await expectDash('dash-2', 7.25);

          // Token variables and arbitrary rem lengths both follow root scale.
          await page.evaluate<void>(
            "() => document.documentElement.style.fontSize = '20px'",
          );
          await expectBox('box-0-0', 25);
          await expectBox('box-2-0', 21.5625);
          final dash = await dimensions('dash-2', true);
          expect(dash['width'], 9.0625);
          expect(
            dash['height'],
            CoreCheckboxStyle.defaultMarkThickness * 1.25,
          );
        }
        expect(errors, isEmpty);
      } finally {
        await browser.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}

import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  for (final theme in ['light', 'dark']) {
    test('$theme holds zero-period Loading at its static pose', () async {
      final directory = Directory.systemTemp.createTempSync('loading-zero-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final body = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          CoUIWeb(
            theme: .coui,
            child: Component.fragment([
              for (final duration in [0, 400, 1000])
                for (final variant in CoreLoadingVariant.values)
                  Loading(
                    id: '${variant.name}-$duration',
                    variant: variant,
                    loadingStyle: CoreLoadingStyle(
                      duration: Duration(milliseconds: duration),
                    ),
                  ),
            ]),
          ),
        ]),
      );
      final file = File('${directory.path}/$theme.html')
        ..writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml: body,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            theme: theme,
            animationFreezeCss: '',
          ),
        );
      final browser = await launchCaptureBrowser(width: 800, height: 600);
      addTearDown(browser.close);
      final page = await browser.newPage();
      await page.goto(file.uri.toString());
      for (final reduce in [false, true, false, true]) {
        await page.emulateMediaFeatures([
          pptr.MediaFeature.prefersReducedMotion(
            reduce ? 'reduce' : 'no-preference',
          ),
        ]);
        await page.evaluate<void>('''
() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))
''');
        for (final duration in [0, 400, 1000]) {
          for (final variant in CoreLoadingVariant.values) {
            final id = '${variant.name}-$duration';
            final value = await page.evaluate<Map<String, Object?>>(
              '''
(id) => {
  const root = document.getElementById(id);
  return {
    animations: root.getAnimations({subtree: true}).map(a => ({
      duration: a.effect.getComputedTiming().duration,
      state: a.playState
    })),
    children: [...root.children].filter(e => e.localName !== 'style').map(e => {
      const style = getComputedStyle(e), matrix = new DOMMatrix(style.transform);
      return {opacity: +style.opacity, scale: matrix.a, dx: matrix.e};
    })
  };
}
''',
              args: [id],
            );
            final animations = value['animations']! as List;
            final stopped = duration == 0 || (reduce && duration == 400);
            if (!stopped) {
              expect(animations, isNotEmpty, reason: '$id reduce=$reduce');
              for (final animation in animations.cast<Map<String, Object?>>()) {
                expect(animation['duration'], duration);
                expect(animation['state'], 'running');
              }
              continue;
            }
            expect(animations, isEmpty, reason: '$id reduce=$reduce');
            final children = (value['children']! as List)
                .cast<Map<String, Object?>>();
            switch (variant) {
              case CoreLoadingVariant.spinner:
                expect(children.last['scale'], 1);
              case CoreLoadingVariant.dots:
                expect(children.map((child) => child['opacity']), [1, 1, 1]);
              case CoreLoadingVariant.bar:
                expect(children.single['dx'], 0);
              case CoreLoadingVariant.pulse:
                expect(children.first['scale'], 1);
                expect(
                  children.first['opacity'],
                  CoreLoadingStyle.defaultPulseHaloAlpha,
                );
            }
          }
        }
      }
    });
  }
}

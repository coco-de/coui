import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  const colors = {
    'opaque': CoreColor(0xFFB12345),
    'alpha': CoreColor(0x80319AC7),
    'zero-alpha': CoreColor(0x00319AC7),
    'transparent': CoreColor.transparent,
    'token': CoreColor.token(CoreColors.warning, opacity: 0.6),
  };

  for (final theme in ['light', 'dark']) {
    test(
      '$theme Loading paints raw and token colors on every variant',
      () async {
        final directory = Directory.systemTemp.createTempSync('loading-color-');
        final browser = await launchCaptureBrowser(width: 800, height: 600);
        addTearDown(browser.close);
        final body = await renderComponentBodyHtml(
          Theme.defaults(
            child: div([
              for (final color in colors.entries) ...[
                span(
                  const [],
                  id: 'reference-${color.key}',
                  styles: Styles(raw: {'color': color.value.toValue()}),
                ),
                for (final variant in CoreLoadingVariant.values)
                  Loading(
                    id: '${color.key}-${variant.name}',
                    variant: variant,
                    classes: 'caller-loading',
                    css: const Styles(
                      raw: {'width': '3rem', 'color': 'rgb(1, 2, 3)'},
                    ),
                    attributes: const {'data-caller': 'kept'},
                    loadingStyle: CoreLoadingStyle(
                      color: color.value,
                      duration: Duration.zero,
                    ),
                  ),
              ],
            ]),
          ),
        );
        final file = File('${directory.path}/$theme.html')
          ..writeAsStringSync(
            buildOfflineTailwindHarnessHtml(
              bodyHtml: body,
              themeConfig: ThemeConfig.defaults(),
              vendoredTailwindScript: loadVendoredTailwindScript(),
              theme: theme,
            ),
          );
        final page = await browser.newPage();
        await page.goto(file.uri.toString());
        await page.waitForFunction('''
() => getComputedStyle(document.getElementById('token-dots').querySelector('span')).backgroundColor
  === getComputedStyle(document.getElementById('reference-token')).color
''');
        for (final color in colors.keys) {
          for (final variant in CoreLoadingVariant.values) {
            final result = await page.evaluate<Map<String, Object?>>(
              '''
(name, variant) => {
  const root = document.getElementById(name + '-' + variant);
  const paint = variant === 'spinner'
    ? [root.querySelector('svg:last-of-type circle')]
    : [...root.children].filter(e => e.localName === 'span');
  return {
    expected: getComputedStyle(document.getElementById('reference-' + name)).color,
    actual: paint.map(e => {
      const style = getComputedStyle(e);
      return variant === 'spinner' ? style.stroke : style.backgroundColor;
    }),
    width: root.getBoundingClientRect().width,
    callerClass: root.classList.contains('caller-loading'),
    callerColor: getComputedStyle(root).color,
    callerAttribute: root.getAttribute('data-caller'),
    role: root.getAttribute('role')
  };
}
''',
              args: [color, variant.name],
            );
            expect(result['actual'], everyElement(result['expected']));
            expect(result['width'], 48);
            expect(result['callerClass'], isTrue);
            expect(result['callerColor'], 'rgb(1, 2, 3)');
            expect(result['callerAttribute'], 'kept');
            expect(result['role'], 'status');
          }
        }
      },
    );
  }
}

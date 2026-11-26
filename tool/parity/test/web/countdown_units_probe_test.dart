import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';

void main() {
  // Reuse the hand-authored tier vectors also read by the established
  // typography probe; deriving expectations from computed CSS would allow
  // a stale mode to pass the width formula against its own old metrics.
  final vectors =
      jsonDecode(
            File(
              'packages/coui_core/test/fixtures/typography_tier_vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final headline = (vectors['roles'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((role) => role['role'] == 'headline-large');
  final chromePath = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
  ].where((candidate) => File(candidate).existsSync()).firstOrNull;

  test(
    'caller shares width after value and mode changes',
    () async {
      final fixture = Directory.systemTemp.createTempSync(
        'coui-countdown-units-',
      );
      pptr.Browser? browser;
      try {
        final js = '${fixture.path}/entry.js';
        final compile = await Process.run(Platform.resolvedExecutable, [
          'compile',
          'js',
          '-O2',
          '-o',
          js,
          'tool/parity/src/web/countdown_units_entry.dart',
        ]);
        expect(
          compile.exitCode,
          0,
          reason: '${compile.stdout}\n${compile.stderr}',
        );
        final html = File('${fixture.path}/index.html')
          ..writeAsStringSync(
            buildOfflineTailwindHarnessHtml(
              bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
              themeConfig: ThemeConfig.defaults(),
              vendoredTailwindScript: File(
                kVendoredTailwindScriptRelativePath,
              ).readAsStringSync(),
              additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
            ),
          );
        browser = await pptr.puppeteer.launch(executablePath: chromePath);
        final page = await browser.newPage();
        await page.setOfflineMode(true);
        await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
        await page.waitForFunction(
          """
() => document.querySelectorAll('[data-countdown-unit]').length === 4
""",
        );
        await page.evaluate<void>('() => document.fonts.ready');

        for (final dark in [false, true]) {
          await page.evaluate<void>(
            """
() => document.documentElement.setAttribute(
  'data-theme', '${dark ? 'dark' : 'light'}')
""",
          );
          for (final tier in ['mobile', 'tablet', 'desktop']) {
            for (final density in ['compact', 'standard', 'spacious']) {
              final expectedFontSize = ((headline[tier] as Map)['size'] as num)
                  .toDouble();
              final expectedInset = CoreDensity.values
                  .byName(density)
                  .space(CoreSpace.space8);
              await page.evaluate<void>('''
() => {
            document.documentElement.setAttribute('data-coui-typography-tier', '$tier');
            document.documentElement.setAttribute('data-coui-density', '$density');
          }''');
              // Mode attributes and tabular-nums alone do not establish that
              // asynchronous styles have reached the requested mode. Wait for
              // its independent type and token expectations on every cell.
              await page.waitForFunction('''
() => [...document.querySelectorAll('[data-countdown-unit]')].every(cell => {
  const digit = getComputedStyle(cell.querySelector('[aria-live]'));
  const surface = getComputedStyle(cell.firstElementChild);
  const row = getComputedStyle(cell.parentElement);
  const near = (actual, expected) =>
    Math.abs(parseFloat(actual) - expected) < 0.01;
  return digit.fontVariantNumeric === 'tabular-nums' &&
    near(digit.fontSize, $expectedFontSize) &&
    near(surface.paddingLeft, $expectedInset) &&
    near(surface.paddingRight, $expectedInset) &&
    near(row.columnGap, $expectedInset);
})
''');
              await page.evaluate<void>('() => document.fonts.ready');
              final widthsByValue = <int, double>{};
              for (final days in [101, 100, 99, 98, 365, 400]) {
                await page.click('#days-$days');
                final shown = math.min(days, 365);
                await page.waitForFunction(
                  """
() => document.querySelector('[data-countdown-unit="0"] [aria-live]')
  .textContent === '$shown'
""",
                );
                await page.evaluate<void>('() => document.fonts.ready');
                // Wait for Tailwind's generated rules and the client rebuild.
                await page.waitForFunction(
                  """
() => getComputedStyle(document.querySelector(
  '[data-countdown-unit] [aria-live]')).fontVariantNumeric === 'tabular-nums'
""",
                );
                final read = (await page.evaluate<List<dynamic>>('''
() => {
              const cells = [...document.querySelectorAll('[data-countdown-unit]')];
              const rect = el => { const r=el.getBoundingClientRect(); return {x:r.x,width:r.width,center:r.x+r.width/2}; };
              return cells.map(cell => {
                const digit=cell.querySelector('[aria-live]');
                const surface=cell.firstElementChild;
                const style=getComputedStyle(surface);
                return {cell:rect(cell),digit:rect(digit),text:digit.textContent,
                  padding:parseFloat(style.paddingLeft)+parseFloat(style.paddingRight),
                  row:rect(cell.parentElement),
                  gap:parseFloat(getComputedStyle(cell.parentElement).columnGap),
                  variant:getComputedStyle(digit).fontVariantNumeric,
                  fontSize:parseFloat(getComputedStyle(digit).fontSize),
                  labels:[...cell.querySelectorAll('span')].filter(el=>!el.hasAttribute('aria-live')).map(rect)};
              });
            }''')).cast<Map<String, dynamic>>();
                final widest = read
                    .map((row) => (row['digit'] as Map)['width'] as num)
                    .reduce(math.max)
                    .toDouble();
                final expected = math.max(
                  56,
                  widest + (read.first['padding'] as num),
                );
                for (final row in read) {
                  final cell = row['cell'] as Map;
                  final digit = row['digit'] as Map;
                  expect(
                    cell['width'],
                    closeTo(expected, 0.05),
                    reason: '$tier/$density days=$days: $read',
                  );
                  expect(digit['center'], closeTo(cell['center'] as num, 0.05));
                  expect(row['variant'], 'tabular-nums');
                  expect(row['fontSize'], closeTo(expectedFontSize, 0.01));
                  expect(row['padding'], closeTo(expectedInset * 2, 0.01));
                  expect(row['gap'], closeTo(expectedInset, 0.01));
                  expect(
                    (row['row'] as Map)['width'],
                    closeTo(
                      (cell['width'] as num) * 4 + (row['gap'] as num) * 3,
                      0.1,
                    ),
                  );
                  for (final label in row['labels'] as List) {
                    expect(
                      (label as Map)['width'],
                      lessThanOrEqualTo(
                        (cell['width'] as num) - (row['padding'] as num) + 0.05,
                      ),
                    );
                  }
                }
                expect(read.first['text'], '$shown');
                final evidence =
                    Platform.environment['COUI_COUNTDOWN_EVIDENCE_DIR'];
                if (evidence != null &&
                    tier == 'desktop' &&
                    density == 'standard' &&
                    (days == 100 || days == 99)) {
                  Directory(evidence).createSync(recursive: true);
                  File(
                    '$evidence/web-${dark ? 'dark' : 'light'}-$days.png',
                  ).writeAsBytesSync(await page.screenshot(fullPage: true));
                }
                widthsByValue[days] =
                    ((read.first['cell'] as Map)['width'] as num).toDouble();
              }
              expect(widthsByValue[101], closeTo(widthsByValue[100]!, 0.05));
              expect(widthsByValue[98], closeTo(widthsByValue[99]!, 0.05));
              // Compact Mobile can fit three digits under the 56 floor.
              expect(
                widthsByValue[100],
                greaterThanOrEqualTo(widthsByValue[99]!),
              );
              if (tier == 'desktop' && density == 'standard') {
                expect(widthsByValue[100], greaterThan(widthsByValue[99]!));
              }
              stdout.writeln(
                'Countdown Web $tier/$density dark=$dark '
                'font=$expectedFontSize inset/gap=$expectedInset '
                '${jsonEncode(widthsByValue.map((k, v) => MapEntry('$k', v)))}',
              );
            }
          }
        }
      } finally {
        await browser?.close();
        fixture.deleteSync(recursive: true);
      }
    },
    skip: chromePath == null
        ? 'Chrome is required for actual layout measurement'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/diff/property_diff.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

const _steps = [
  CoreStepItem(label: 'Step 1', description: 'Account details'),
  CoreStepItem(label: 'Step 2'),
  CoreStepItem(label: 'Step 3'),
];

// SSR supplies the production component tree; Chrome, real fonts and the
// production stylesheet perform the layout. This is not a CSS-string test.
const _measure = '''
() => {
  const output = {};
  for (const root of document.querySelectorAll('[id^="stepper-"]')) {
    output[root.id] = [...root.children].map(row => {
      const indicator = row.children[0];
      const content = row.children[2];
      const label = content.children[0];
      const r = row.getBoundingClientRect();
      const l = label.getBoundingClientRect();
      const circle = indicator.children[0].getBoundingClientRect();
      const connector = indicator.children[1]?.getBoundingClientRect();
      return {height:r.height, titleTop:l.top-r.top, titleHeight:l.height,
        lineHeight:parseFloat(getComputedStyle(label).lineHeight),
        descriptionHeight:content.children[2]?.getBoundingClientRect().height ?? null,
        circleHeight:circle.height,
        connector:connector?.height ?? null,
        connectorTop:connector ? connector.top-r.top : null,
        connectorBottom:connector ? r.bottom-connector.bottom : null};
    });
  }
  return JSON.stringify(output);
}''';

void main() {
  late pptr.Browser browser;
  late pptr.Page page;
  late Directory work;
  late Map<String, dynamic> measurements;

  setUpAll(() async {
    final body = await renderComponentBodyHtml(
      Theme.defaults(
        child: div([
          for (final name in [
            'default',
            'disabled',
            'multiline',
            'diameter',
            'type',
            'state-type',
            'padding',
            'compact',
            'spacious',
            'full',
            'fixed-tie',
          ])
            div(
              [
                Stepper(
                  id: 'stepper-$name',
                  steps: name == 'multiline'
                      ? [
                          const CoreStepItem(label: 'Step 1 Second line'),
                          ..._steps.skip(1),
                        ]
                      : name == 'full'
                      ? const [
                          CoreStepItem(
                            label: 'Step 1',
                            description: 'Account details',
                          ),
                          CoreStepItem(
                            label: 'Step 2',
                            description: 'Payment info',
                          ),
                          CoreStepItem(
                            label: 'Step 3',
                            description: 'Review & submit',
                          ),
                        ]
                      : _steps,
                  currentStep: 1,
                  enabled: name != 'disabled',
                  orientation: .vertical,
                  stepperStyle: switch (name) {
                    'diameter' => const CoreStepperStyle(indicatorSize: 32),
                    'type' => const CoreStepperStyle(
                      labelStyle: CoreTextStyle(fontSize: 20),
                    ),
                    'state-type' => const CoreStepperStyle(
                      labelActiveStyle: CoreTextStyle(lineHeight: 1.8),
                      labelUpcomingStyle: CoreTextStyle(fontSize: 10),
                    ),
                    'fixed-tie' => const CoreStepperStyle(
                      labelStyle: CoreTextStyle(lineHeightPx: 21.5),
                    ),
                    'padding' => const CoreStepperStyle(
                      stepPadding: CoreEdgeInsets.only(top: 4, bottom: 12),
                    ),
                    _ => null,
                  },
                ),
              ],
              attributes: {
                if (name == 'compact' || name == 'spacious')
                  kDensityAttribute: name,
              },
              styles: Styles(
                raw: {
                  'width': name == 'multiline' ? '100px' : '300px',
                  'margin-bottom': '16px',
                },
              ),
            ),
        ]),
      ),
    );
    work = Directory.systemTemp.createTempSync('stepper-alignment-');
    final file = File('${work.path}/probe.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml:
              '<style>${buildLocalFontFaceCss()} body{margin:0}</style>',
        ),
      );
    browser = await launchCaptureBrowser(
      width: 800,
      height: 1600,
      executablePath: [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/usr/bin/google-chrome',
        '/usr/bin/chromium',
      ].firstWhere((candidate) => File(candidate).existsSync()),
    );
    page = await browser.newPage();
    await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
    await page.evaluate<Object?>('() => document.fonts.ready');
    await page.evaluate<Object?>(
      '() => new Promise(r => requestAnimationFrame(() => '
      'requestAnimationFrame(r)))',
    );
    measurements =
        jsonDecode(await page.evaluate<String>(_measure))
            as Map<String, dynamic>;
    File('/tmp/stepper-web-geometry.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(measurements),
    );
    File(
      '/tmp/stepper-web-geometry.png',
    ).writeAsBytesSync(await page.screenshot(fullPage: true));
  });

  tearDownAll(() async {
    await browser.close();
    work.deleteSync(recursive: true);
  });

  test(
    'copy geometry keeps native subpixels within the existing tolerance',
    () {
      for (final name in ['default', 'disabled']) {
        final rows = measurements['stepper-$name'] as List;
        for (var i = 0; i < 3; i++) {
          final row = rows[i] as Map;
          expect(row['height'], closeTo([65, 43, 24][i], kPxTolerance));
          expect(
            row['titleTop'],
            closeTo((24 - (row['lineHeight'] as num).round()) / 2, .02),
          );
          if (i < 2) {
            expect(row['connector'], closeTo([33, 11][i], kPxTolerance));
            expect(row['connectorTop'], closeTo(28, .01));
            expect(row['connectorBottom'], closeTo(4, .01));
          } else {
            expect(row['connector'], isNull);
          }
        }
      }
      // Keep the raw sample; rounding it would conceal regressions.
      stdout.writeln(
        'Native Web Stepper: ${jsonEncode(measurements['stepper-default'])}',
      );
    },
  );

  test(
    'typography, wrapping, diameter, density and insets remain effective',
    () {
      for (final entry in measurements.entries) {
        for (final (index, raw) in (entry.value as List).indexed) {
          final row = raw as Map;
          final authoredTop = entry.key == 'stepper-padding' && index < 2
              ? 4
              : 0;
          final expected =
              ((row['circleHeight'] as num) -
                  (row['lineHeight'] as num).round()) /
              2;
          expect(
            row['titleTop'],
            closeTo(authoredTop + (expected > 0 ? expected : 0), .02),
            reason: '${entry.key} row $index',
          );
        }
      }
      final multiline =
          (measurements['stepper-multiline'] as List).first as Map;
      expect(
        multiline['titleHeight'],
        greaterThan(multiline['lineHeight'] as num),
      );
      expect(
        ((measurements['stepper-compact'] as List).first as Map)['height'],
        lessThan(
          ((measurements['stepper-default'] as List).first as Map)['height']
              as num,
        ),
      );
      expect(
        ((measurements['stepper-spacious'] as List).first as Map)['height'],
        greaterThan(
          ((measurements['stepper-default'] as List).first as Map)['height']
              as num,
        ),
      );
    },
  );

  test(
    'alignment projection preserves native line and paragraph layout',
    () async {
      final full = (measurements['stepper-full'] as List)
          .cast<Map<String, dynamic>>();
      // Every line sits in the whole-pixel box Flutter's engine lays it out
      // in: 16 × 1.4 = 22.4 draws 22, 13 × 1.5 = 19.5 draws 20.
      expect(full.first['lineHeight'], 22);
      expect(full.first['titleHeight'], 22);
      expect(full.first['descriptionHeight'], 20);
      expect(
        full.take(2).map((r) => r['height']),
        everyElement(closeTo(65, .01)),
      );
      expect(
        full
            .map((r) => r['height'] as num)
            .reduce((sum, height) => sum + height),
        closeTo(175, .01),
      );
      // The final row omits the authored 20px bottom padding.
      expect(full.last['height'], closeTo(45, .01));
      final tie = (measurements['stepper-fixed-tie'] as List).first as Map;
      // A stated 21.5 box is a tie: it draws 22 on both platforms.
      expect(tie['lineHeight'], 22);
      expect(tie['titleHeight'], 22);
      expect(
        tie['titleTop'],
        1,
        reason: 'positive .5 rounds upward, as in Flutter',
      );
      // Remove only the alignment geometry. The rendered text must not change.
      await page.evaluate<Object?>(
        '''
      () => {
        for (const root of document.querySelectorAll('[id^="stepper-"]')) {
          for (const row of root.children) row.children[2].style.paddingTop = '0px';
        }
      }'''
            .trim(),
      );
      final withoutAlignment =
          jsonDecode(await page.evaluate<String>(_measure)) as Map;
      for (final entry in measurements.entries) {
        final before = entry.value as List;
        final after = withoutAlignment[entry.key] as List;
        for (var i = 0; i < before.length; i++) {
          final beforeRow = before[i] as Map;
          final afterRow = after[i] as Map;
          for (final metric in [
            'lineHeight',
            'titleHeight',
            'descriptionHeight',
          ]) {
            expect(
              afterRow[metric],
              beforeRow[metric],
              reason: '${entry.key} $i $metric',
            );
          }
        }
      }
      await page.reload(wait: .load);
      await page.evaluate<Object?>('() => document.fonts.ready');
    },
  );

  test(
    'root font scaling recomputes rather than scales a cached one-pixel offset',
    () async {
      for (final rootSize in [21, 24]) {
        await page.evaluate<Object?>(
          '() => { document.documentElement.style.fontSize="${rootSize}px"; }',
        );
        final scaled = jsonDecode(await page.evaluate<String>(_measure)) as Map;
        final first = (scaled['stepper-default'] as List).first as Map;
        expect(
          first['titleTop'],
          rootSize == 21 ? 1.25 : 1,
        );
        for (final entry in scaled.entries) {
          for (final (index, raw) in (entry.value as List).indexed) {
            final row = raw as Map;
            final authoredTop = entry.key == 'stepper-padding' && index < 2
                ? 4 * rootSize / 16
                : 0;
            final offset =
                ((row['circleHeight'] as num) -
                    (row['lineHeight'] as num).round()) /
                2;
            expect(
              row['titleTop'],
              closeTo(authoredTop + (offset > 0 ? offset : 0), .02),
              reason: '${entry.key} row $index at root $rootSize',
            );
          }
        }
      }
    },
  );
}

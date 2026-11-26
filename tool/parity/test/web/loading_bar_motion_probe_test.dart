import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/loading_bar_motion_cases.dart';

void main() {
  late Directory directory;
  late pptr.Browser browser;
  late String body;
  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('loading-bar-motion-');
    browser = await launchCaptureBrowser(width: 800, height: 700);
    body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        for (final scenario in kLoadingBarMotionCases)
          CoUIWeb(
            theme: ThemeData.coui.copyWith(
              coreComponentTheme: CoreComponentTheme(loading: scenario.theme),
            ),
            child: Loading(
              id: scenario.name,
              variant: .bar,
              componentSize: scenario.componentSize,
              loadingStyle: scenario.style,
            ),
          ),
      ]),
    );
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });
  for (final theme in ['light', 'dark']) {
    test(
      '$theme: actual SSR registers a numeric phase and follows the full cycle',
      () async {
        final file = File('${directory.path}/$theme.html')
          ..writeAsStringSync(
            buildOfflineTailwindHarnessHtml(
              bodyHtml: body,
              themeConfig: ThemeConfig.defaults(),
              vendoredTailwindScript: loadVendoredTailwindScript(),
              theme: theme,
              animationFreezeCss: kCaptureInitialAnimationCss,
            ),
          );
        final page = await browser.newPage();
        try {
          await page.goto(file.uri.toString());
          final syntax = await page.evaluate<String>('''
() => [...document.styleSheets].flatMap(s=>[...s.cssRules]).find(r=>r.name==='--co-loading-bar-phase').syntax
''');
          expect(
            syntax,
            '<number>',
            reason: 'unregistered custom properties animate discretely',
          );
          final rows = <Map<String, Object?>>[];
          for (final scenario in kLoadingBarMotionCases) {
            for (final phase in kLoadingBarMotionPhases) {
              final value =
                  jsonDecode(
                        await page.evaluate<String>('''
() => {
const root=document.getElementById('${scenario.name}'), fill=root.querySelector('.co-loading-bar');
const a=fill.getAnimations()[0];a.pause();a.currentTime=${phase * scenario.durationMs};
const c=getComputedStyle(fill), m=new DOMMatrix(c.transform);
const r=root.getBoundingClientRect(), f=fill.getBoundingClientRect();
return JSON.stringify({phase:parseFloat(c.getPropertyValue('--co-loading-bar-phase')),
 dx:m.m41,length:r.width,fill:f.width,height:r.height,duration:a.effect.getTiming().duration});
}
'''),
                      )
                      as Map;
              final eased = CoreEasing.move.transform(phase % 1);
              final expected =
                  (scenario.length *
                      (1 - CoreLoadingStyle.defaultBarFillRatio)) *
                  math.sin(eased * math.pi);
              expect(value['duration'], scenario.durationMs);
              expect(value['length'], closeTo(scenario.length, 0.02));
              expect(value['height'], closeTo(scenario.height, 0.02));
              expect(
                value['phase'],
                closeTo(eased, 0.0001),
                reason: '${scenario.name} t=$phase',
              );
              expect(
                value['dx'],
                closeTo(expected, 0.03),
                reason: '${scenario.name} t=$phase',
              );
              rows.add({
                'case': scenario.name,
                't': phase,
                'actual': value,
                'expectedDx': expected,
              });
            }
          }
          // Different times on two fills must not share the registered value.
          final independent =
              jsonDecode(
                    await page.evaluate<String>('''
() => {
 const a=document.querySelector('#theme .co-loading-bar'),b=document.querySelector('#instance .co-loading-bar');
 a.getAnimations()[0].currentTime=500;b.getAnimations()[0].currentTime=1237*.75;
 return JSON.stringify([getComputedStyle(a).getPropertyValue('--co-loading-bar-phase'),getComputedStyle(b).getPropertyValue('--co-loading-bar-phase')]);
}
'''),
                  )
                  as List;
          expect(double.parse(independent[0] as String), lessThan(.2));
          expect(double.parse(independent[1] as String), greaterThan(.8));
          final evidence = Platform.environment['COUI_LOADING_MOTION_EVIDENCE'];
          if (evidence != null) {
            Directory(evidence).createSync(recursive: true);
            File('$evidence/web-$theme.json').writeAsStringSync(
              const JsonEncoder.withIndent('  ').convert(rows),
            );
          }
        } finally {
          await page.close();
        }
      },
    );
  }
}

import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pp;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/diff/property_diff.dart';
import '../../src/model/property_snapshot.dart';
import '../../src/normalize/web_property_normalizer.dart';
import '../../src/web/computed_style_probe.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

String? _chromePath() {
  for (final path in const [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
  ]) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

BoxShadowLayer _layer({
  double x = 0,
  double y = 4,
  double blur = 6,
  double spread = 2,
  bool inset = false,
  String blurStyle = 'normal',
}) => BoxShadowLayer(
  offsetX: x,
  offsetY: y,
  blur: blur,
  spread: spread,
  color: NormalizedColor(r: 12, g: 34, b: 56, a: 0.125),
  inset: inset,
  blurStyle: blurStyle,
);

bool _fieldMatches(
  PropertySnapshot native,
  PropertySnapshot web,
  String field,
) => comparePropertySnapshots(
  flutter: native,
  web: web,
).fields.firstWhere((entry) => entry.field == field).matches;

void main() {
  final chromePath = _chromePath();
  group('paint observation through real Chrome and production comparator', () {
    late pp.Browser browser;
    late pp.Page page;
    late Directory directory;

    setUpAll(() async {
      browser = await launchCaptureBrowser(
        width: 400,
        height: 300,
        executablePath: chromePath,
      );
      directory = Directory.systemTemp.createTempSync('paint-observation-');
    });
    tearDownAll(() async {
      await browser.close();
      directory.deleteSync(recursive: true);
    });
    setUp(() async {
      page = await browser.newPage();
      await page.setOfflineMode(true);
    });
    tearDown(() => page.close());

    Future<Map<String, Object?>> capture(String style) async {
      final file = File('${directory.path}/control.html')
        ..writeAsStringSync('''
<!doctype html><html><body>
<div id="paint" style="width:80px;height:60px;background:rgb(200,210,220);$style"></div>
</body></html>''');
      await page.goto(file.uri.toString(), wait: pp.Until.load);
      return (await captureComputedStyle(page, '#paint'))!;
    }

    PropertySnapshot normalize(Map<String, Object?> raw) =>
        normalizeWebSnapshot(
          raw,
          key: 'paint',
          probeRole: 'root',
        );
    PropertySnapshot shadow(List<BoxShadowLayer> layers) => PropertySnapshot(
      key: 'paint',
      platform: 'flutter',
      probeRole: 'root',
      boxShadow: layers,
    );
    const absent = PropertySnapshot(
      key: 'paint',
      platform: 'flutter',
      probeRole: 'root',
    );

    test(
      'transparent raw shadow layers agree with none in both formats',
      () async {
        for (final color in [
          'rgba(12,34,56,0)',
          'color(srgb 1 0.5 0.25 / 0)',
        ]) {
          final raw = await capture('box-shadow:$color 7px 9px 24px 4px;');
          expect(raw['boxShadow'], isNot('none'));
          final web = normalize(raw);
          expect(web.boxShadow, isEmpty);
          expect(_fieldMatches(absent, web, 'boxShadow'), isTrue);
          expect(web.borderWidthPx, 0);
          expect(web.paddingPx, const FourSidePx(0, 0, 0, 0));
        }
      },
    );

    test('visible geometry, colour and layer order stay observable', () async {
      final expected = shadow([_layer()]);
      final correct = normalize(
        await capture(
          'box-shadow:rgba(99,88,77,0) 20px 30px 40px 5px, '
          'rgba(12,34,56,.125) 0px 4px 6px 2px;',
        ),
      );
      expect(_fieldMatches(expected, correct, 'boxShadow'), isTrue);
      for (final css in [
        'rgba(12,34,56,.125) 0px 8px 6px 2px',
        'rgba(12,34,56,.125) 0px 4px 12px 2px',
        'rgba(12,34,56,.125) 0px 4px 6px 5px',
        'rgba(99,34,56,.125) 0px 4px 6px 2px',
      ]) {
        expect(
          _fieldMatches(
            expected,
            normalize(await capture('box-shadow:$css;')),
            'boxShadow',
          ),
          isFalse,
          reason: css,
        );
      }
      final ordered = shadow([_layer(), _layer(x: 8)]);
      final sameOrder = normalize(
        await capture(
          'box-shadow:rgba(12,34,56,.125) 0px 4px 6px 2px, '
          'color(srgb 0.0470588 0.133333 0.219608 / .125) 8px 4px 6px 2px;',
        ),
      );
      expect(_fieldMatches(ordered, sameOrder, 'boxShadow'), isTrue);
      final reversed = normalize(
        await capture(
          'box-shadow:rgba(12,34,56,.125) 8px 4px 6px 2px, '
          'rgba(12,34,56,.125) 0px 4px 6px 2px;',
        ),
      );
      expect(_fieldMatches(ordered, reversed, 'boxShadow'), isFalse);
    });

    test(
      'positive alpha below colour rounding retains its shadow layer',
      () async {
        for (final color in [
          // Chrome quantizes legacy rgba alpha .0004 to computed zero;
          // Color-4 preserves it (and serializes smaller alpha as 1e-7).
          'color(srgb 1 0.5 0.25 / .0004)',
          'color(srgb 1 0.5 0.25 / .0000001)',
        ]) {
          final web = normalize(
            await capture('box-shadow:$color 0px 4px 6px 2px;'),
          );
          expect(web.boxShadow, hasLength(1));
          expect(web.boxShadow!.single.color.a, 0);
          expect(_fieldMatches(absent, web, 'boxShadow'), isFalse);
        }
      },
    );

    test(
      'visible inset and non-normal SDK masks cannot equal an outer cast',
      () async {
        final outer = normalize(
          await capture('box-shadow:rgba(12,34,56,.125) 0px 4px 6px 2px;'),
        );
        final inner = normalize(
          await capture(
            'box-shadow:rgba(12,34,56,.125) 0px 4px 6px 2px inset;',
          ),
        );
        expect(outer.boxShadow!.single.inset, isFalse);
        expect(inner.boxShadow!.single.inset, isTrue);
        expect(_fieldMatches(shadow([_layer()]), inner, 'boxShadow'), isFalse);
        expect(
          _fieldMatches(shadow([_layer(inset: true)]), inner, 'boxShadow'),
          isTrue,
        );
        for (final kind in ['inner', 'outer', 'solid']) {
          expect(
            _fieldMatches(
              shadow([_layer(blurStyle: kind)]),
              outer,
              'boxShadow',
            ),
            isFalse,
            reason: kind,
          );
        }
      },
    );

    test(
      'raw outline colour adds known absence without rewriting legacy values',
      () async {
        final raw = await capture(
          'outline:3px solid rgba(12,34,56,0);outline-offset:2px; '
          'border:1px solid rgb(78,90,12);padding:10px 11px 12px 13px;',
        );
        expect(raw['outlineColor'], 'rgba(12, 34, 56, 0)');
        expect(raw['outlineWidth'], '3px');
        final web = normalize(raw);
        expect(web.outlineWidthPx, 0);
        expect(web.outlineOffsetPx, 2);
        expect(web.borderWidthPx, 1);
        expect(web.paddingPx, const FourSidePx(10, 11, 12, 13));
        expect(_fieldMatches(absent, web, 'outlineWidthPx'), isTrue);
        expect(_fieldMatches(absent, web, 'outlineOffsetPx'), isTrue);
        final legacy = normalize({...raw}..remove('outlineColor'));
        expect(legacy.outlineWidthPx, 3);
        expect(legacy.outlineOffsetPx, 2);
        expect(_fieldMatches(absent, legacy, 'outlineWidthPx'), isFalse);
      },
    );

    test(
      'visible and faint outlines retain wrong width and offset failures',
      () async {
        const native = PropertySnapshot(
          key: 'paint',
          platform: 'flutter',
          probeRole: 'root',
          outlineWidthPx: 3,
          outlineOffsetPx: 2,
        );
        for (final color in [
          'rgba(12,34,56,.125)',
          'color(srgb 1 0.5 0.25 / .0004)',
          'color(srgb 1 0.5 0.25 / .0000001)',
        ]) {
          final matching = normalize(
            await capture('outline:3px solid $color;outline-offset:2px;'),
          );
          expect(matching.outlineWidthPx, 3);
          expect(_fieldMatches(native, matching, 'outlineWidthPx'), isTrue);
          expect(_fieldMatches(absent, matching, 'outlineWidthPx'), isFalse);
          final wrongWidth = normalize(
            await capture('outline:6px solid $color;outline-offset:2px;'),
          );
          expect(_fieldMatches(native, wrongWidth, 'outlineWidthPx'), isFalse);
          final wrongOffset = normalize(
            await capture('outline:3px solid $color;outline-offset:6px;'),
          );
          expect(
            _fieldMatches(native, wrongOffset, 'outlineOffsetPx'),
            isFalse,
          );
        }
      },
    );

    test(
      'public Button rest and focused input keep different paint visibility',
      () async {
        final body = await renderComponentBodyHtml(
          CoUIWeb(
            theme: .coui,
            child: Button(
              onPressed: () {},
              child: const Text('Observe'),
            ).primary,
          ),
        );
        final file = File('${directory.path}/button.html')
          ..writeAsStringSync(
            buildOfflineTailwindHarnessHtml(
              bodyHtml: body,
              themeConfig: ThemeConfig.defaults(),
              vendoredTailwindScript: loadVendoredTailwindScript(),
            ),
          );
        await page.goto(file.uri.toString(), wait: pp.Until.load);
        final resting = (await captureComputedStyle(page, 'button'))!;
        expect(resting['outlineColor'], 'rgba(0, 0, 0, 0)');
        expect(normalize(resting).outlineWidthPx, 0);
        await (await page.$('button')).focus();
        await page.waitForFunction('''
() => document.querySelector('button').matches(':focus-visible') &&
  getComputedStyle(document.querySelector('button')).outlineColor !==
    'rgba(0, 0, 0, 0)'
''');
        final focused = (await captureComputedStyle(page, 'button'))!;
        expect(normalize(focused).outlineWidthPx, 2);
        expect(
          _fieldMatches(absent, normalize(focused), 'outlineWidthPx'),
          isFalse,
        );
      },
    );
  }, skip: chromePath == null ? 'Chrome executable unavailable' : null);
}

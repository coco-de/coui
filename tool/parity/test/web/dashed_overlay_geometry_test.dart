import 'dart:io';
import 'dart:math' as math;

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' show Browser, Page, Until;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  late Browser browser;
  late Directory directory;
  late Page page;
  final config = ThemeConfig.defaults();
  final tailwind = loadVendoredTailwindScript();

  setUpAll(() async {
    browser = await launchCaptureBrowser(width: 400, height: 300);
    directory = Directory.systemTemp.createTempSync('dashed-overlay-geometry-');
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });
  setUp(() async => page = await browser.newPage());
  tearDown(() => page.close());

  Future<Map<String, Object?>> geometry(
    CoreSurfaceStyleId style, {
    double radius = CoreRadius.radius16,
  }) async {
    final body = await renderComponentBodyHtml(
      CoUIWeb(
        theme: .coui,
        child: Frame(
          id: 'frame',
          width: CoreSpace.space120,
          height: CoreSpace.space80,
          borderColor: const CoreColor.token(CoreColors.outline),
          borderWidth: CoreStrokeWidth.stroke2,
          borderStyle: .dashed,
          borderRadius: CoreBorderRadius.all(radius),
          child: const Text('Frame'),
        ),
      ),
    );
    final file = File('${directory.path}/frame.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: config,
          vendoredTailwindScript: tailwind,
          surfaceStyleId: style.name,
        ),
      );
    await page.goto(Uri.file(file.path).toString(), wait: Until.load);
    return await page.evaluate<Map<String, Object?>>(
      '''
    () => {
      const host = document.querySelector('#frame');
      const rect = host.querySelector('svg rect');
      const edge = getComputedStyle(rect);
      return {
        rx: edge.rx,
        hostRadius: getComputedStyle(host).borderTopLeftRadius,
        stroke: edge.strokeWidth,
      };
    }'''
          .trim(),
    );
  }

  for (final style in [
    CoreSurfaceStyleId.defaultId,
    CoreSurfaceStyleId.neoBrutalism,
    CoreSurfaceStyleId.claymorphism,
    CoreSurfaceStyleId.neumorphism,
  ]) {
    test(
      '$style applies the Core radius and stroke to the actual SVG',
      () async {
        final actual = await geometry(style);
        final expected = CoreSurfaceRecipe.of(style).geometry;
        expect(
          double.parse((actual['rx']! as String).replaceAll('px', '')),
          math.max(
            0,
            expected.radius(CoreRadius.radius16) -
                expected.stroke(CoreStrokeWidth.stroke2) / 2,
          ),
        );
        expect(
          double.parse((actual['hostRadius']! as String).replaceAll('px', '')),
          expected.radius(CoreRadius.radius16),
        );
        expect(
          double.parse((actual['stroke']! as String).replaceAll('px', '')),
          expected.stroke(CoreStrokeWidth.stroke2),
        );
      },
    );
  }

  test(
    'a live radius variable override reaches the host and its stroke',
    () async {
      await geometry(CoreSurfaceStyleId.defaultId);
      final actual = await page.evaluate<Map<String, Object?>>(
        '''
    () => {
      document.documentElement.style.setProperty('--coui-radius-16', '11px');
      const host = document.querySelector('#frame');
      return {
        host: getComputedStyle(host).borderTopLeftRadius,
        stroke: getComputedStyle(host.querySelector('svg rect')).rx,
      };
    }'''
            .trim(),
      );
      expect(actual, {'host': '11px', 'stroke': '10px'});
    },
  );

  test('an off-scale caller radius remains a literal', () async {
    final actual = await geometry(
      CoreSurfaceStyleId.neoBrutalism,
      radius: 7.25,
    );
    expect(actual['rx'], '5.25px');
    expect(actual['hostRadius'], '7.25px');
  });
}
